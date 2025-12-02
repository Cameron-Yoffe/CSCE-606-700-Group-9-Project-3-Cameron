class AddRewatchToDiaryEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :diary_entries, :rewatch, :boolean, default: false, null: false
    add_index :diary_entries, :rewatch
  end
end
