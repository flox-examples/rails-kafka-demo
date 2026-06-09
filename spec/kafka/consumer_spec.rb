require "rails_helper"

RSpec.describe Kafka::Consumer do
  describe ".handle" do
    let!(:post) { create(:post, status: "pending") }

    it "marks the post as processed" do
      message = instance_double("Rdkafka::Consumer::Message",
        payload: { id: post.id, status: "processed" }.to_json,
        offset: 0)
      described_class.handle(message)
      expect(post.reload.status).to eq("processed")
    end

    it "tolerates a missing post without raising" do
      message = instance_double("Rdkafka::Consumer::Message",
        payload: { id: 99999 }.to_json,
        offset: 1)
      expect { described_class.handle(message) }.not_to raise_error
    end

    it "tolerates malformed JSON without raising" do
      message = instance_double("Rdkafka::Consumer::Message",
        payload: "not-json",
        offset: 2)
      expect { described_class.handle(message) }.not_to raise_error
    end
  end
end
