# rails-kafka-demo

A production-shaped Rails 7 + Postgres + Kafka app, configured with **Flox** as its
baseline dev environment. It serves as the primary service in a two-repo demo that shows
cross-repo Kafka event flow and shared config.

The companion repo is **[kafka-audit-service](../kafka-audit-service)**, which consumes
events published here and exposes a query API that this app calls back.

## What's included

| Layer | Detail |
|---|---|
| Rails 7.2 API | `Post` CRUD — creates trigger `posts.created` Kafka events |
| Postgres 16 | Provided as a Flox service; no host install needed |
| Kafka (KRaft) | Single-broker, no Zookeeper; also a Flox service |
| `rdkafka` gem | Native C extension linked against Flox-managed `librdkafka` |
| Kafka consumer | `bin/kafka_consumer` — listens on `posts.processed`, updates `Post#status` |
| HTTP → audit service | `GET /posts/:id` fetches audit logs from kafka-audit-service |
| RSpec suite | Runs against real Postgres; Kafka is stubbed (no broker needed for tests) |
| CI | GitHub Actions — Postgres via service container, `librdkafka` apt-installed |

---

## Prerequisites

Install [Flox](https://flox.dev/docs/install-flox/) — follow the instructions for your
platform. On macOS:

```bash
brew install flox
```

---

## Quick start

```bash
# 1. Clone both repos side by side
git clone <this-repo> rails-kafka-demo
git clone <companion-repo> kafka-audit-service

# 2. Enter the Flox environment (installs Ruby 3.3, librdkafka, Postgres 16, Kafka)
cd rails-kafka-demo
flox activate

# 3. Copy env file and adjust if needed
cp .env.example .env.local

# 4. Start Postgres + Kafka
flox services start

# 5. Run setup (bundle install + db create/migrate + kafka topics)
bin/setup

# 6. Start the Rails server
bin/rails server -p 3000
```

In a second terminal:
```bash
cd rails-kafka-demo
flox activate
bin/kafka_consumer
```

---

## Running tests

Tests run against a real Postgres database. Kafka is stubbed — no broker needed.

```bash
flox activate
bundle exec rspec
```

The test database is created automatically from `db/schema.rb` when you run the setup script.
To reset it manually:

```bash
RAILS_ENV=test bin/rails db:drop db:create db:schema:load
```

---

## Running the linter

```bash
bundle exec rubocop
```

---

## Shared config with kafka-audit-service

Both repos read the same environment variables. The easiest local workflow:

1. Edit `.env.local` in this repo with your Kafka/Postgres connection details.
2. The `kafka-audit-service` on-activate hook sources `../rails-kafka-demo/.env.local`
   automatically — so you only maintain one file.

Key variables:

| Variable | Default | Purpose |
|---|---|---|
| `KAFKA_BROKERS` | `localhost:9092` | Shared Kafka broker address |
| `PGHOST` / `PGPORT` / `PGUSER` | `127.0.0.1 / 5432 / postgres` | Shared Postgres |
| `AUDIT_SERVICE_URL` | `http://localhost:3001` | kafka-audit-service base URL |

---

## Flox services

```bash
flox services start    # start Postgres + Kafka in background
flox services stop     # stop all
flox services restart  # restart
flox services status   # status
```

Kafka runs in **KRaft mode** (no Zookeeper). Postgres data lives in the Flox environment
cache — delete it to wipe local state.

---

## Kafka topics

| Topic | Direction | Schema |
|---|---|---|
| `posts.created` | published by this app | `{id, title, body, status, created_at}` |
| `posts.processed` | consumed by this app | `{id, status}` |

Create topics manually:
```bash
bin/rails kafka:create_topics
```

Publish a test event:
```bash
bin/rails "kafka:publish_test[My test title]"
```

---

## Project layout

```
app/
  controllers/posts_controller.rb   — CRUD + audit service call
  kafka/producer.rb                 — singleton rdkafka producer
  kafka/consumer.rb                 — posts.processed handler
  models/post.rb                    — publishes Kafka event after_create_commit
bin/
  kafka_consumer                    — long-running consumer process
  start-kafka                       — KRaft init + start (called by Flox services)
config/
  kafka.yml                         — shared Kafka config (env-var driven)
  kafka/kraft-server.properties     — KRaft broker template
.flox/env/manifest.toml             — Flox environment definition (packages + services)
```
