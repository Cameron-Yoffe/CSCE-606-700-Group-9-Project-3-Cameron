class UpdateReviewReactionsForEmojis < ActiveRecord::Migration[8.1]
  def change
    # Remove the old reaction_type column and add emoji instead
    remove_column :review_reactions, :reaction_type
    add_column :review_reactions, :emoji, :string, null: false, default: "👍"

    # Remove old unique index and add new one with emoji
    remove_index :review_reactions, [ :rating_id, :user_id ]
    add_index :review_reactions, [ :rating_id, :user_id, :emoji ], unique: true
  end
end
