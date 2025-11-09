class ExpertAssignment < ApplicationRecord
  belongs_to :conversation
  belongs_to :expert_profile, foreign_key: :expert_id
end