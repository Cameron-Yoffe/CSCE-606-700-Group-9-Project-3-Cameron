class CreateFollows < ActiveRecord::Migration[8.1]
  def change
    create_table :follows do |t|
      t.integer :follower_id, null: false
      t.integer :followed_id, null: false
      t.string :status, default: "accepted", null: false

      t.timestamps
    end

    add_index :follows, :follower_id
    add_index :follows, :followed_id
    add_index :follows, %i[follower_id followed_id], unique: true
    add_foreign_key :follows, :users, column: :follower_id
    add_foreign_key :follows, :users, column: :followed_id
  end
end
