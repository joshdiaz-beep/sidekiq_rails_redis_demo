class WelcomeEmailJob < ApplicationJob
  queue_as :mailers

  # This method is what the Sidekiq WORKER process calls, not the
  # Rails web process. By the time this runs, the HTTP request that
  # created the user has already finished and returned a response
  # to the browser.
  def perform(user_id)
    user = User.find(user_id)

    # Simulate a slow operation, like calling a third-party email API.
    sleep 3

    Rails.logger.info("[WelcomeEmailJob] Sent welcome email to #{user.email} at #{Time.current}")
  end
end
