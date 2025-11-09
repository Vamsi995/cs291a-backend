class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.string :title
      t.string :status
      t.bigint :initiator_id
      t.bigint :assigned_expert_id

      t.timestamps
    end
  end
end
