# User Signup Demo — Rails + Sidekiq + Kafka

This is a minimal Rails app that demonstrates:

- Classic **Redis + Sidekiq** background jobs for internal work (sending a welcome email).
- **Kafka + DeliveryBoy + Racecar** for publishing and consuming `user_created` domain events.

The concrete use case is simple on purpose: a user signs up with just an email address. Behind the scenes, the app saves the user, sends a welcome email asynchronously, and publishes a `user_created` event to Kafka for any downstream consumers.

---

## High‑level flow

1. A user fills out a form with just an email address (`/users/new`).
2. Submitting the form hits `UsersController#create`, which:
   - Saves the user to Postgres immediately.
   - Enqueues `WelcomeEmailJob` to Sidekiq (via Redis).
   - Publishes a `user_created` event to the Kafka topic `user-events` (via DeliveryBoy).
3. A separate **Sidekiq worker** process pops the job from the `mailers` queue and “sends” the email (simulated delay).
4. A separate **Racecar consumer** (`UserCreatedConsumer`) subscribes to `user-events` and reacts to each `user_created` event.

The web request returns quickly; all the slow work happens in background processes.

---

## Prerequisites (macOS)

Local host (Rails/Sidekiq):

- Ruby 3.3+
- Bundler
- Node/Yarn (whatever your Rails version normally requires)

Infra via Docker:

- Docker Desktop (with Compose v2)
- No Postgres/Redis/Kafka processes bound to the same ports on the host

Optional local services (if you prefer non‑Docker Postgres/Redis):

- PostgreSQL running locally (default port 5432)
- Redis running locally (default port 6379)

---

## Services and ports

By default, infra is run with Docker Compose and Rails/Sidekiq run on the host:

- Postgres: `localhost:5432` (Docker service `db`)
- Redis: `localhost:6379` (Docker service `redis`)
- Kafka broker: `localhost:9092` (Docker service `kafka`)
- Rails: `http://localhost:3000`
- Sidekiq Web UI: `http://localhost:3000/sidekiq`

If you already have Postgres or Redis running locally, either stop them or adjust the port mappings in `docker-compose.yml`.

---

## Setup

From the project root:

```bash
bundle install
bin/rails db:create db:migrate
```

Start infra (Postgres, Redis, Kafka) via Docker:

```bash
docker compose up -d
docker compose ps
```

You should see `db`, `redis`, and `kafka` in a `Running` state.

Create the Kafka topic used by this app (once):

```bash
docker compose exec kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --create \
  --topic user-events \
  --partitions 3 \
  --replication-factor 1
```

- **Partitions = 3**: gives us ordering per user (via partition key) and room for parallel consumers.
- **Replication factor = 1**: fine for local dev on a single broker.

---

## Running it (4 terminals)

**Terminal 1 — Rails server**

```bash
bin/rails server
```

**Terminal 2 — Sidekiq worker**

```bash
bundle exec sidekiq -C config/sidekiq.yml
```

**Terminal 3 — Racecar consumer (Kafka)**

```bash
bundle exec racecar UserCreatedConsumer
```

This boots Rails inside the consumer and subscribes to the `user-events` topic.

**Terminal 4 — (optional) Kafka topic inspection**

List topics:

```bash
docker compose exec kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server localhost:9092 \
  --list
```

---

## Try it out

1. Visit `http://localhost:3000/users/new` and create a user with an email.
2. The app will:
   - Save the user to Postgres.
   - Enqueue `WelcomeEmailJob` to the `mailers` queue.
   - Publish a `user_created` event to Kafka.
3. Open `http://localhost:3000/sidekiq` in another tab:
   - You should briefly see 1 job in the `mailers` queue.
   - It should move from “Enqueued” to “Processed” after a short delay.
4. Watch the **Sidekiq** and **Racecar** terminals:
   - Sidekiq: logs from `WelcomeEmailJob` (“Sent welcome email to …”).
   - Racecar: logs from `UserCreatedConsumer` (“Received user_created event …”).

---

## Code tour (read in this order)

Core Sidekiq flow:

- `app/controllers/users_controller.rb` — saves the user, enqueues `WelcomeEmailJob`, and calls `EventPublisher.user_created`.
- `app/jobs/welcome_email_job.rb` — the actual background work for the welcome email.
- `config/initializers/sidekiq.rb` — how Sidekiq connects to Redis.
- `config/application.rb` — tells ActiveJob to use Sidekiq as the backend.
- `config/routes.rb` — where the Sidekiq dashboard is mounted at `/sidekiq`.

Kafka publishing & consumption:

- `app/services/event_publisher.rb`  
  Builds a JSON event and uses DeliveryBoy to publish to the `user-events` topic, using the user id as the `partition_key`. This keeps all events for a given user ordered on the same partition.
- `config/delivery_boy.yml`  
  Producer configuration (brokers, client id).
- `app/consumers/user_created_consumer.rb`  
  Racecar consumer that subscribes to `user-events`, parses each message, and runs `handle_user_created`.
- `config/racecar.yml` (if present)  
  Consumer configuration (brokers, consumer group, etc.).

Infrastructure:

- `docker-compose.yml` — Postgres, Redis, and Kafka services and their port mappings.

---

## Mental model

On user signup:

1. **Synchronous path**: Rails handles the HTTP request, validates the email, and writes one `users` row in Postgres.
2. **Background job path**: Rails enqueues a job to Redis; Sidekiq workers pull from Redis and send the welcome email later.
3. **Event stream path**: Rails publishes a `user_created` event to Kafka; Racecar consumers subscribe to that topic and can do anything they want (analytics, CRM, logging, etc.) without changing the signup controller.

Sidekiq is “do this job for me,” Kafka is “this happened; whoever cares should react.”

---

## Future next steps / TODOs

Planned enhancements (not implemented yet):

- Containerize the Rails app and Sidekiq worker into Docker (so everything runs under Compose).
- Add a second consumer for `user_updated` events to show multi‑event handling.
- Add a basic analytics or logging consumer to demonstrate multiple independent consumers reading from the same topic.
- Wire AWS CDK to provision the same stack (Rails ECS service, Sidekiq workers, RDS, ElastiCache Redis, MSK/Kafka) in AWS.

Contributions / PRs that move toward those steps (especially containerizing Rails + Sidekiq) are very welcome.