# This file configures BOTH sides of the Sidekiq/Redis connection.
#
# configure_client runs inside the Rails web process. It is used
# whenever your code calls `SomeJob.perform_later` -- it pushes a
# serialized job payload onto a Redis list (the queue).
#
# configure_server runs inside the `bundle exec sidekiq` worker
# process. It is used to pop jobs off that same Redis list and
# execute their `perform` method.
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end
