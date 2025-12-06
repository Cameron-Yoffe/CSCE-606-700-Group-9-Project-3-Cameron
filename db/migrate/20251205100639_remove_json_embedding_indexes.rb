class RemoveJsonEmbeddingIndexes < ActiveRecord::Migration[8.1]
  def change
    remove_index :movies, :embedding if index_exists?(:movies, :embedding)
    remove_index :movies, :movie_embedding if index_exists?(:movies, :movie_embedding)
    remove_index :users, :embedding if index_exists?(:users, :embedding)
    remove_index :users, :user_embedding if index_exists?(:users, :user_embedding)
  end
end
