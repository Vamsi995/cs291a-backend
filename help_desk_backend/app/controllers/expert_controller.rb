class ExpertController < ApplicationController
  include ::AuthHelper 
  before_action :authenticate!
  before_action :require_expert!

  def queue
    waiting = Conversation
                .where(status: 'waiting')
                .where.not(initiator_id: current_user.id)          # hide my own conversations
                # .where.not(assigned_expert_id: current_user.id)    # (redundant for waiting, but safe)
                .includes(:messages, :initiator)

    assigned = Conversation
                .assigned_to(current_user.id)
                .includes(:messages, :initiator)

    render json: {
      waitingConversations: waiting.map   { |c| ConversationSerializer.new(c).as_json },
      assignedConversations: assigned.map { |c| ConversationSerializer.new(c).as_json }
    }
  end

  def claim
    convo = Conversation.find(params[:conversation_id])
    if convo.assigned_expert_id.present?
      return render json: { error: "Conversation is already assigned to an expert" }, status: :unprocessable_entity # :contentReference[oaicite:19]{index=19}
    end
    convo.update!(assigned_expert_id: current_user.id, status: "active")
    ExpertAssignment.create!(conversation_id: convo.id, expert_id: current_user.expert_profile.id, status: "active", assigned_at: Time.current)
    render json: { success: true } # :contentReference[oaicite:20]{index=20}
  end

  def unclaim
    convo = Conversation.find(params[:conversation_id])
    return render json: { error: "You are not assigned to this conversation" }, status: :forbidden unless convo.assigned_expert_id == current_user.id # :contentReference[oaicite:21]{index=21}
    convo.update!(assigned_expert_id: nil, status: "waiting")
    render json: { success: true } # :contentReference[oaicite:22]{index=22}
  end

  def profile
    render json: ExpertProfileSerializer.new(current_user.expert_profile).as_json # :contentReference[oaicite:23]{index=23}
  end

  def update_profile
    ep = current_user.expert_profile
    ep.update!(bio: params[:bio], knowledge_base_links: params[:knowledgeBaseLinks])
    render json: ExpertProfileSerializer.new(ep).as_json # :contentReference[oaicite:24]{index=24}
  end

  def history
    assignments = current_user.expert_profile.expert_assignments.order(assigned_at: :desc)
    render json: assignments.map { |a| {
      id: a.id.to_s, conversationId: a.conversation_id.to_s, expertId: a.expert_id.to_s,
      status: a.status, assignedAt: a.assigned_at&.iso8601, resolvedAt: a.resolved_at&.iso8601, rating: a.rating
    } } # :contentReference[oaicite:25]{index=25}
  end

  private

  def require_expert!
    puts current_user.expert_profile
    render json: { error: "Expert profile required" }, status: :forbidden unless current_user&.expert_profile
  end
end
