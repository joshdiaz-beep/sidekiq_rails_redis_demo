# User Signup Demo — Redis + Sidekiq Fundamentals

This is a minimal Rails app built to demonstrate the Redis + Sidekiq
background job pattern using a realistic use case: creating a user
and sending a "welcome email" asynchronously.

## What this demonstrates

1. A user fills out a form with just an email address (`/`).
2. Submitting the form saves the user to Postgres immediately.
3. Instead of sending a welcome email synchronously (which would make
   the browser wait for however long an email API takes), the
   controller calls `WelcomeEmailJob.perform_later(@user.id)`.
4. That call serializes the job and pushes it onto a Redis queue.
   The HTTP response returns to the browser instantly.
5. A separate Sidekiq worker process, running independently, pops
   the job off Redis and executes it — including a simulated 3-second
   delay to represent a slow third-party API call.
6. You can watch the job move from "Enqueued" to "Processed" live in
   the Sidekiq Web dashboard at `/sidekiq`.

## Prerequisites

- Ruby 3.3+
- PostgreSQL running locally
- Redis running locally (`redis-server`)

## Setup

```bash
bundle install
bin/rails db:create db:migrate
```

## Running it (3 terminals)

Terminal 1 — Redis:
```bash
redis-server
```

Terminal 2 — Rails server:
```bash
bin/rails server
```

Terminal 3 — Sidekiq worker:
```bash
bundle exec sidekiq -C config/sidekiq.yml
```

## Try it out

1. Visit `http://localhost:3000` and create a user with an email.
2. Notice the page redirects instantly — the "email" hasn't actually
   been sent yet.
3. Open `http://localhost:3000/sidekiq` in another tab.
4. Watch the `mailers` queue: you'll briefly see 1 job enqueued, then
   it drops to 0 and the "Processed" counter increments about 3
   seconds later.
5. Check your Rails server or Sidekiq terminal logs for the line:
   `[WelcomeEmailJob] Sent welcome email to ...`

## Files worth reading, in order

- `app/controllers/users_controller.rb` — where the job gets enqueued.
- `app/jobs/welcome_email_job.rb` — the actual background work.
- `config/initializers/sidekiq.rb` — how Sidekiq finds Redis.
- `config/application.rb` — the line that tells ActiveJob to use Sidekiq.
- `config/routes.rb` — where the Sidekiq dashboard gets mounted.
