# app/controllers/updates_controller.rb
class UpdatesController < ApplicationController
  include ::AuthHelper
  before_action :authenticate!

  # GET /api/conversations/updates?userId=me&since=2025-11-08T23:00:00Z
  def conversations
    user_id = resolve_user_id!(params[:userId]) # raises 400 if missing/invalid
    since   = parse_since(params[:since])

    # Only conversations the user can see
    convos = Conversation.visible_to(current_user)
                         .includes(:messages)
                         .includes(:initiator) # expects conversation.belongs_to :initiator, class_name: "User"
    convos = convos.where("conversations.updated_at >= ?", since) if since

    render json: convos.map { |c| convo_json(c) }
  end

  # GET /api/messages/updates?userId=me&since=2025-11-08T23:00:00Z
  def messages
    user_id = resolve_user_id!(params[:userId])
    since   = parse_since(params[:since])

    msgs = Message.joins(:conversation)
                  .merge(Conversation.visible_to(current_user))
                  .includes(:conversation, :sender)
    msgs = msgs.where("messages.created_at >= ?", since) if since
    msgs = msgs.order("messages.created_at ASC")

    render json: msgs.map { |m| message_json(m) }
  end

  # GET /api/expert-queue/updates?expertId=me&since=2025-11-08T23:00:00Z
  # def expert_queue
  #   expert_user_id = resolve_expert_user_id!(params[:expertId]) # raises 400 if missing/invalid
  #   since          = parse_since(params[:since])

  #   # Waiting = unassigned
  #   waiting = Conversation.where(status: "waiting")
  #   waiting = waiting.where("updated_at >= ?", since) if since
  #   waiting = waiting.includes(:messages, :initiator)

  #   # Assigned to this expert
  #   assigned = Conversation.where(assigned_expert_id: expert_user_id)
  #   assigned = assigned.where("updated_at >= ?", since) if since
  #   assigned = assigned.includes(:messages, :initiator)

  #   payload = [
  #     {
  #       waitingConversations: waiting.map { |c| convo_json(c) },
  #       assignedConversations: assigned.map { |c| convo_json(c) }
  #     }
  #   ]

  #   render json: payload
  # end
  # GET /api/expert-queue/updates?expertId=me&since=2025-11-08T23:00:00Z
  def expert_queue
    # Resolve expert id but always trust the JWT identity to avoid impersonation
    user_id = resolve_expert_user_id!(params[:expertId])
    since          = parse_since(params[:since])

    expert_user = ExpertProfile.find_by(user_id: user_id)
    puts "here"
    puts user_id
    puts expert_user.id
    # Waiting = unassigned conversations not involving the current user
    waiting = Conversation.where(status: "waiting")
                          .where.not(initiator_id: user_id)
                          # .where.not(assigned_expert_id: expert_user_id)
    waiting = waiting.where("updated_at >= ?", since) if since
    waiting = waiting.includes(:messages, :initiator)

    # "Assigned" list but still exclude anything involving the current user
    # (i.e., show active conversations assigned to OTHER experts, not me)
    assigned = assigned = Conversation.where(assigned_expert_id: expert_user.id)
    assigned = assigned.where("updated_at >= ?", since) if since
    assigned = assigned.includes(:messages, :initiator)

    render json: [
      {
        waitingConversations: waiting.map  { |c| convo_json(c) },
        assignedConversations: assigned.map { |c| convo_json(c) }
      }
    ]
  end

# GET /api/expert-queue/updates?expertId=me&since=2025-11-08T23:00:00Z
  # def expert_queue
  #   expert_user_id = resolve_expert_user_id!(params[:expertId])
  #   since = parse_since(params[:since])

  #   # Only include conversations the current expert is NOT part of:
  #   waiting = Conversation.where(status: "waiting")
  #                         .where.not(initiator_id: current_user.id)
  #                         .where.not(assigned_expert_id: current_user.id)
  #   waiting = waiting.where("updated_at >= ?", since) if since
  #   waiting = waiting.includes(:messages, :initiator)

  #   assigned = Conversation.where(status: "active")
  #                         .where.not(initiator_id: current_user.id)
  #                         .where.not(assigned_expert_id: current_user.id)
  #   assigned = assigned.where("updated_at >= ?", since) if since
  #   assigned = assigned.includes(:messages, :initiator)

  #   payload = [
  #     {
  #       waitingConversations: waiting.map { |c| convo_json(c) },
  #       assignedConversations: assigned.map { |c| convo_json(c) }
  #     }
  #   ]

  #   render json: payload
  # end



  private

  # ---------- helpers ----------

  # Resolve "me" or explicit id for normal user endpoints
  def resolve_user_id!(raw)
    raise_bad_request!("userId is required") if raw.blank?
    return current_user.id if raw == "me"
    Integer(raw)
  rescue ArgumentError
    raise_bad_request!("userId must be an integer or 'me'")
  end

  # Resolve "me" or explicit id for expert endpoints (the spec uses expertId but it's still a user id)
  def resolve_expert_user_id!(raw)
    raise_bad_request!("expertId is required") if raw.blank?
    return current_user.id if raw == "me"
    Integer(raw)
  rescue ArgumentError
    raise_bad_request!("expertId must be an integer or 'me'")
  end

  def parse_since(raw)
    return nil if raw.blank?
    Time.iso8601(raw)
  rescue ArgumentError
    nil
  end

  def raise_bad_request!(msg)
    render json: { error: msg }, status: :bad_request and return
  end

  # Build the conversation JSON exactly as in the spec
  #
  # Spec fields:
  #   id, title, status, questionerId, questionerUsername,
  #   assignedExpertId, assignedExpertUsername, createdAt, updatedAt,
  #   lastMessageAt, unreadCount
  #
  # Assumptions:
  # - Conversation has: id, title, status, initiator_id, assigned_expert_id, timestamps
  # - Associations:
  #     belongs_to :initiator, class_name: "User", foreign_key: :initiator_id
  #     (optional) belongs_to :assigned_expert, class_name: "User", foreign_key: :assigned_expert_id, optional: true
  # - Message has: sender_id, is_read, created_at
  # def convo_json(convo, viewer_id:)
#     def convo_json(c)
#   ConversationSerializer.new(c).as_json
# end
    # eager data
    # initiator = convo.respond_to?(:initiator) ? convo.initiator : User.find(convo.initiator_id)
    # assigned  = convo.assigned_expert_id.present? ? User.find_by(id: convo.assigned_expert_id) : nil

    # msgs = if convo.association(:messages).loaded?
    #          convo.messages
    #        else
    #          convo.messages
    #        end

    # last_msg_at = msgs.maximum(&:created_at) if msgs.respond_to?(:maximum)
    # last_msg_at ||= msgs.order(created_at: :desc).limit(1).pluck(:created_at).first rescue nil

    # # unread = messages not sent by viewer and not read
    # unread_count = if msgs.loaded?
    #                  msgs.count { |m| m.sender_id != viewer_id && !m.is_read }
    #                else
    #                  convo.messages.where.not(sender_id: viewer_id).where(is_read: false).count
    #                end

    # {
    #   id: convo.id.to_s,
    #   title: convo.title,
    #   status: convo.status,
    #   questionerId: convo.initiator_id.to_s,
    #   questionerUsername: initiator&.username,
    #   assignedExpertId: convo.assigned_expert_id&.to_s,
    #   assignedExpertUsername: assigned&.username,
    #   createdAt: convo.created_at&.iso8601,
    #   updatedAt: convo.updated_at&.iso8601,
    #   lastMessageAt: last_msg_at&.iso8601,
    #   unreadCount: unread_count
    # }
  # end
  def convo_json(c)
    ConversationSerializer.new(c).as_json
  end

  # Build the message JSON exactly as in the spec
  #
  # Spec fields:
  #   id, conversationId, senderId, senderUsername, senderRole, content, timestamp, isRead
  #
  # Assumptions:
  # - Message belongs_to :conversation, :sender (sender is User via sender_id)
  # - Conversation has initiator_id and assigned_expert_id
  def message_json(m)
    sender   = m.respond_to?(:sender) ? m.sender : User.find(m.sender_id)
    convo    = m.respond_to?(:conversation) ? m.conversation : Conversation.find(m.conversation_id)
    sender_role =
      if sender.id == convo.initiator_id
        "initiator"
      else
        "expert"
      end

    {
      id: m.id.to_s,
      conversationId: m.conversation_id.to_s,
      senderId: m.sender_id.to_s,
      senderUsername: sender&.username,
      senderRole: sender_role,
      content: m.content,
      timestamp: m.created_at&.iso8601,
      isRead: !!m.is_read
    }
  end
end
