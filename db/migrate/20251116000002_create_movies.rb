class CreateMovies < ActiveRecord::Migration[8.1]
  def change
    create_table :movies do |t|
      t.string :title, null: false
      t.text :description
      t.integer :tmdb_id
      t.string :poster_url
      t.string :backdrop_url
      t.float :vote_average
      t.integer :vote_count
      t.date :release_date
      t.integer :runtime
      t.text :genres, default: "[]"
      t.string :director
      t.text :cast, default: "[]"
      t.timestamps
    end

    add_index :movies, :tmdb_id, unique: true
    add_index :movies, :title
    add_index :movies, :release_date
  end
end
