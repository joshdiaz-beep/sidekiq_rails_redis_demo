require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module UserSignupDemo
  class Application < Rails::Application
    config.load_defaults 7.1

    # This tells ActiveJob to hand off all perform_later jobs
    # to Sidekiq instead of running them inline in the same process.
    config.active_job.queue_adapter = :sidekiq
  end
end
