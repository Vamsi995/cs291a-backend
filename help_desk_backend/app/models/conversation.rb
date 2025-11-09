class Conversation < ApplicationRecord
  belongs_to :initiator, class_name: "User"
  has_many :messages, dependent: :destroy
  has_many :expert_assignments, dependent: :destroy
  scope :waiting, -> { where(status: "waiting") }
  scope :assigned_to, -> (user_id) { where(assigned_expert_id: user_id) }
  def self.visible_to(user)
    where("initiator_id = ? OR assigned_expert_id = ?", user.id, user.id)
  end
end