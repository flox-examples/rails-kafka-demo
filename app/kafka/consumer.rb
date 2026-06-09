require "rdkafka"

module Kafka
  class Consumer
    TOPIC = Rails.application.config_for(:kafka)["topic_posts_processed"]
    GROUP_ID = Rails.application.config_for(:kafka)["consumer_group"]

    def self.run
      Rails.logger.info "[Kafka::Consumer] Starting — topic=#{TOPIC} group=#{GROUP_ID}"

      consumer = Rdkafka::Config.new(
        "bootstrap.servers" => Rails.application.config_for(:kafka)["brokers"],
        "group.id" => GROUP_ID,
        "auto.offset.reset" => "earliest",
        "enable.auto.commit" => "true"
      ).consumer

      consumer.subscribe(TOPIC)

      consumer.each do |message|
        handle(message)
      end
    rescue Rdkafka::RdkafkaError => e
      Rails.logger.error "[Kafka::Consumer] Fatal error: #{e.message}"
      raise
    end

    def self.handle(message)
      payload = JSON.parse(message.payload, symbolize_names: true)
      Rails.logger.info "[Kafka::Consumer] posts.processed post_id=#{payload[:id]}"

      Post.find_by(id: payload[:id])&.update!(status: "processed")
    rescue JSON::ParserError => e
      Rails.logger.error "[Kafka::Consumer] Bad JSON at offset #{message.offset}: #{e.message}"
    rescue ActiveRecord::RecordNotFound
      Rails.logger.warn "[Kafka::Consumer] Post #{payload&.dig(:id)} not found — skipping"
    end
  end
end
