# app/consumers/user_created_consumer.rb
class UserCreatedConsumer < Racecar::Consumer
  subscribes_to "user-events"

  def process(message)
    payload = JSON.parse(message.value)

    case payload["name"]
    when "user_created"
      handle_user_created(payload["data"])
    else
      Rails.logger.warn("[UserCreatedConsumer] Unknown event: #{payload['name']}")
    end
  end

  private

  def handle_user_created(data)
    Rails.logger.info("[UserCreatedConsumer] New user signed up: #{data['email']} (id=#{data['id']})")
    # Real work goes here: sync to CRM, trigger analytics pipeline, etc.
    # This runs independently of WelcomeEmailJob and does not affect it if this consumer is down.
  end
end