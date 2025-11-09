class MessageSerializer
  def initialize(m) @m=m end
  def as_json(*)
    {
      id: @m.id.to_s,
      conversationId: @m.conversation_id.to_s,
      senderId: @m.sender_id.to_s,
      senderUsername: @m.sender.username,
      senderRole: @m.sender_role,
      content: @m.content,
      timestamp: @m.created_at&.iso8601,
      isRead: @m.is_read
    }
  end
end