require "sidekiq/web"

Rails.application.routes.draw do
  # Mounting Sidekiq::Web gives you a dashboard at /sidekiq
  # to see enqueued, processed, and failed jobs in real time.
  mount Sidekiq::Web => "/sidekiq"

  root "users#new"

  resources :users, only: [:new, :create, :index]
end
