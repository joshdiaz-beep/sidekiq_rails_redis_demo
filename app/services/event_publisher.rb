# app/services/event_publisher.rb
class EventPublisher
  def self.user_created(user)
    event = {
      name: "user_created",
      data: {
        id: user.id,
        email: user.email,
        created_at: user.created_at.iso8601
      }
    }

    DeliveryBoy.deliver_async(
      event.to_json,
      topic: "user-events",
      partition_key: user.id.to_s
    )
  end
end