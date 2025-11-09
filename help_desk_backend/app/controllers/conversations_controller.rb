class ConversationsController < ApplicationController
  include ::AuthHelper 
  before_action :authenticate!

  def index
    convos = Conversation.visible_to(current_user)
    render json: convos.map { |c| ConversationSerializer.new(c, current_user: current_user).as_json } # :contentReference[oaicite:8]{index=8}
  end

  def show
    convo = Conversation.find_by(id: params[:id])
    return render json: { error: "Conversation not found" }, status: :not_found unless convo # :contentReference[oaicite:9]{index=9}
    authorize_conversation!(convo)
    render json: ConversationSerializer.new(convo, current_user: current_user).as_json # :contentReference[oaicite:10]{index=10}
  end

  def create
    convo = Conversation.new(title: params[:title], initiator_id: current_user.id, status: "waiting")
    if convo.save
      render json: ConversationSerializer.new(convo, current_user: current_user).as_json, status: :created # :contentReference[oaicite:11]{index=11}
    else
      render json: { errors: convo.errors.full_messages }, status: :unprocessable_entity # :contentReference[oaicite:12]{index=12}
    end
  end

  private

  def authorize_conversation!(convo)
    ok = (convo.initiator_id == current_user.id) || (convo.assigned_expert_id == current_user.id)
    render(json: { error: "Forbidden" }, status: :forbidden) unless ok
  end
end
