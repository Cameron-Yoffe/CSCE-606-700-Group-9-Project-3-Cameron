class CreateReviewReactions < ActiveRecord::Migration[8.1]
  def change
    create_table :review_reactions do |t|
      t.references :rating, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :reaction_type, default: 0, null: false  # 0 for like, 1 for dislike

      t.timestamps
    end

    add_index :review_reactions, [ :rating_id, :user_id ], unique: true
  end
end
