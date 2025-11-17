class CreateRatings < ActiveRecord::Migration[8.1]
  def change
    create_table :ratings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :movie, null: false, foreign_key: true
      t.integer :value, null: false
      t.text :review
      t.timestamps
    end

    add_index :ratings, [ :user_id, :movie_id ], unique: true
    add_index :ratings, :value
  end
end
