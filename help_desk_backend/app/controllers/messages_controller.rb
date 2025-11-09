class MessagesController < ApplicationController
  include ::AuthHelper 
  before_action :authenticate!

  def index
    convo = Conversation.find(params[:conversation_id])
    authorize_conversation!(convo)
    msgs = convo.messages.includes(:sender)
    render json: msgs.map { |m| MessageSerializer.new(m).as_json } # :contentReference[oaicite:13]{index=13}
  end

  def create
    convo = Conversation.find_by(id: params[:conversationId]) || Conversation.find_by(id: params[:conversation_id])
    return render json: { error: "Conversation not found" }, status: :not_found unless convo # :contentReference[oaicite:14]{index=14}
    authorize_conversation!(convo)
    msg = convo.messages.build(sender_id: current_user.id,
                               sender_role: (convo.initiator_id == current_user.id ? "initiator" : "expert"),
                               content: params[:content])
    if msg.save
      render json: MessageSerializer.new(msg).as_json, status: :created # :contentReference[oaicite:15]{index=15}
    else
      render json: { errors: msg.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def read
    msg = Message.find(params[:id])
    return render json: { error: "Cannot mark your own messages as read" }, status: :forbidden if msg.sender_id == current_user.id # :contentReference[oaicite:16]{index=16}
    msg.update!(is_read: true)
    render json: { success: true } # :contentReference[oaicite:17]{index=17}
  end

  private

  def authorize_conversation!(convo)
    ok = (convo.initiator_id == current_user.id) || (convo.assigned_expert_id == current_user.id)
    render(json: { error: "Forbidden" }, status: :forbidden) unless ok
  end
end
