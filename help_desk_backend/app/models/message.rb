class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, class_name: "User"
  validates :sender_role, inclusion: { in: %w[initiator expert] }
end