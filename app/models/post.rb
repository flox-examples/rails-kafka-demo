class Post < ApplicationRecord
  STATUSES = %w[pending processing processed failed].freeze

  validates :title, presence: true, length: { maximum: 255 }
  validates :body, presence: true
  validates :status, inclusion: { in: STATUSES }

  after_create_commit :publish_created_event

  def to_kafka_payload
    { id: id, title: title, body: body, status: status, created_at: created_at.iso8601 }
  end

  private

  def publish_created_event
    Kafka::Producer.publish(
      topic: Rails.application.config_for(:kafka)["topic_posts_created"],
      payload: to_kafka_payload,
      key: id.to_s
    )
  rescue => e
    Rails.logger.error "[Kafka] Failed to publish posts.created for Post##{id}: #{e.message}"
  end
end
