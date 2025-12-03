class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :notifiable, polymorphic: true, null: false
      t.string :notification_type, null: false
      t.boolean :read, default: false, null: false

      t.timestamps
    end

    add_index :notifications, %i[user_id read]
    add_index :notifications, %i[user_id created_at]
  end
end
