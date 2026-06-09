require "rdkafka"

module Kafka
  class Producer
    def self.publish(topic:, payload:, key: nil)
      return if Rails.env.test? && !ENV["KAFKA_ENABLED_IN_TESTS"]

      handle = rdkafka_producer.produce(
        topic: topic,
        payload: payload.is_a?(String) ? payload : payload.to_json,
        key: key&.to_s
      )
      handle.wait(max_wait_timeout: 5)
    rescue Rdkafka::RdkafkaError => e
      Rails.logger.error "[Kafka::Producer] #{e.message} (topic=#{topic})"
      raise
    end

    def self.close
      @rdkafka_producer&.close
      @rdkafka_producer = nil
    end

    def self.rdkafka_producer
      @rdkafka_producer ||= Rdkafka::Config.new(
        "bootstrap.servers" => kafka_config["brokers"],
        "client.id" => "rails-kafka-demo-producer",
        "message.timeout.ms" => "5000"
      ).producer
    end
    private_class_method :rdkafka_producer

    def self.kafka_config
      Rails.application.config_for(:kafka)
    end
    private_class_method :kafka_config
  end
end
