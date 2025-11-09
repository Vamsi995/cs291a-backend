class CreateExpertAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :expert_assignments do |t|
      t.references :conversation, null: false, foreign_key: true
      t.bigint :expert_id
      t.string :status
      t.datetime :assigned_at
      t.datetime :resolved_at
      t.integer :rating

      t.timestamps
    end
  end
end
