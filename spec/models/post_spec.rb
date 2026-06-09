require "rails_helper"

RSpec.describe Post, type: :model do
  describe "validations" do
    subject { build(:post) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:title).is_at_most(255) }
    it { is_expected.to validate_inclusion_of(:status).in_array(Post::STATUSES) }
  end

  describe "Kafka publishing" do
    it "publishes posts.created after create" do
      post = build(:post)
      post.save!
      expect(Kafka::Producer).to have_received(:publish).with(
        topic: "posts.created",
        payload: hash_including(id: post.id, title: post.title),
        key: post.id.to_s
      )
    end

    it "does not raise if Kafka publish fails" do
      allow(Kafka::Producer).to receive(:publish).and_raise(StandardError, "broker unreachable")
      expect { create(:post) }.not_to raise_error
    end

    it "does not publish on update" do
      post = create(:post)
      allow(Kafka::Producer).to receive(:publish).and_call_original
      post.update!(status: "processed")
      expect(Kafka::Producer).not_to have_received(:publish)
    end
  end

  describe "#to_kafka_payload" do
    it "includes expected fields" do
      post = create(:post)
      payload = post.to_kafka_payload
      expect(payload).to include(:id, :title, :body, :status, :created_at)
    end
  end
end
