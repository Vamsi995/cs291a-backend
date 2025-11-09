class ConversationSerializer
  def initialize(c, current_user: nil) @c=c; @u=current_user end
  def as_json(*)
    {
      id: @c.id.to_s,
      title: @c.title,
      status: @c.status,
      questionerId: @c.initiator_id.to_s,
      questionerUsername: @c.initiator.username,
      assignedExpertId: @c.assigned_expert_id&.to_s,
      assignedExpertUsername: @c.assigned_expert_id ? User.find(@c.assigned_expert_id).username : nil,
      createdAt: @c.created_at&.iso8601,
      updatedAt: @c.updated_at&.iso8601,
      lastMessageAt: @c.messages.maximum(:created_at)&.iso8601,
      unreadCount: @u ? @c.messages.where.not(sender_id: @u.id).where(is_read: false).count : 0
    }
  end
end