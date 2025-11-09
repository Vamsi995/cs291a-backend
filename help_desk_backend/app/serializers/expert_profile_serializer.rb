class ExpertProfileSerializer
  def initialize(ep) @ep=ep end
  def as_json(*)
    {
      id: @ep.id.to_s,
      userId: @ep.user_id.to_s,
      bio: @ep.bio,
      knowledgeBaseLinks: @ep.knowledge_base_links,
      createdAt: @ep.created_at&.iso8601,
      updatedAt: @ep.updated_at&.iso8601
    }
  end
end