class AddTopPositionToFavorites < ActiveRecord::Migration[8.1]
  def change
    add_column :favorites, :top_position, :integer
    add_index :favorites, [:user_id, :top_position], unique: true, where: "top_position IS NOT NULL"
  end
end
