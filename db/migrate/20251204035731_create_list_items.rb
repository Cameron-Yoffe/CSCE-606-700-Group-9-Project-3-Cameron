class CreateListItems < ActiveRecord::Migration[7.1]
  def change
    create_table :list_items do |t|
      t.references :list, null: false, foreign_key: true
      t.references :movie, null: false, foreign_key: true

      t.timestamps
    end

    add_index :list_items, [ :list_id, :movie_id ], unique: true
  end
end
