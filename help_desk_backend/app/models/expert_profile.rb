class ExpertProfile < ApplicationRecord
  belongs_to :user
  has_many :expert_assignments, foreign_key: :expert_id
  attribute :knowledge_base_links, :json, default: []
end
