# app/consumers/dev_events_consumer.rb
class DevEventsConsumer < Racecar::Consumer
  subscribes_to "dev-events"

  def process(message)
    payload = JSON.parse(message.value)
    Rails.logger.info("[DevEventsConsumer] Received: #{payload.inspect}")
  end
end