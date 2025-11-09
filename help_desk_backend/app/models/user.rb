class User < ApplicationRecord
  has_secure_password
  has_many :conversations, foreign_key: :initiator_id
  has_many :messages, foreign_key: :sender_id
  has_one :expert_profile, inverse_of: :user, dependent: :destroy

  # spec says: expert profiles are auto-created on register
  after_create :ensure_expert_profile!
  
  private
  def ensure_expert_profile!
    create_expert_profile! unless expert_profile
  end
end