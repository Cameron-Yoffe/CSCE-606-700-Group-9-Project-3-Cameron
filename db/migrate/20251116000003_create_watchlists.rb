class CreateWatchlists < ActiveRecord::Migration[8.1]
  def change
    create_table :watchlists do |t|
      t.references :user, null: false, foreign_key: true
      t.references :movie, null: false, foreign_key: true
      t.string :status, default: 'to_watch'
      t.timestamps
    end

    add_index :watchlists, [ :user_id, :movie_id ], unique: true
    add_index :watchlists, :status
  end
end
