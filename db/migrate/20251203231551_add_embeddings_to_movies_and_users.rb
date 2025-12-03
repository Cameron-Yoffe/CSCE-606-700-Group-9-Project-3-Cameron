class AddEmbeddingsToMoviesAndUsers < ActiveRecord::Migration[7.1]
  def change
    json_type = postgres? ? :jsonb : :json

    # guard to avoid duplicate column errors
    add_column_if_absent(:movies, :movie_embedding, json_type, default: {}, null: false)
    add_column_if_absent(:users, :user_embedding, json_type, default: {}, null: false)

    add_movie_index_options = postgres? ? { using: :gin } : {}
    add_user_index_options = postgres? ? { using: :gin } : {}

    add_index :movies, :movie_embedding, **add_movie_index_options unless index_exists?(:movies, :movie_embedding)
    add_index :users, :user_embedding, **add_user_index_options unless index_exists?(:users, :user_embedding)
  end

  private

  def postgres?
    connection.adapter_name.casecmp("PostgreSQL").zero?
  end

  def add_column_if_absent(table, column, type, **options)
    if column_exists?(table, column)
      say("#{table}.#{column} already exists; skipping add_column", true)
      return
    end

    add_column(table, column, type, **options)
  end
end