namespace :kafka do
  desc "Start Kafka consumer (blocks; run in a separate terminal)"
  task consume: :environment do
    Kafka::Consumer.run
  end

  desc "Publish a test posts.created event to Kafka"
  task :publish_test, [:title] => :environment do |_, args|
    title = args[:title] || "Test post #{Time.now.to_i}"
    post = Post.create!(title: title, body: "Body created by rake kafka:publish_test")
    puts "Created Post##{post.id} and published posts.created event"
  end

  desc "Create required Kafka topics"
  task create_topics: :environment do
    config = Rails.application.config_for(:kafka)
    brokers = config["brokers"]
    topics = [config["topic_posts_created"], config["topic_posts_processed"]]
    topics.each do |topic|
      system("kafka-topics.sh --bootstrap-server #{brokers} " \
             "--create --if-not-exists --topic #{topic} " \
             "--partitions 1 --replication-factor 1")
      puts "Topic #{topic} ready"
    end
  end
end
