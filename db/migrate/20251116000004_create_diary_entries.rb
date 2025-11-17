class CreateDiaryEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :diary_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.references :movie, null: false, foreign_key: true
      t.text :content, null: false
      t.date :watched_date
      t.string :mood
      t.integer :rating, default: 0
      t.timestamps
    end

    add_index :diary_entries, [:user_id, :movie_id]
    add_index :diary_entries, [:user_id, :watched_date]
    add_index :diary_entries, :watched_date
  end
end
