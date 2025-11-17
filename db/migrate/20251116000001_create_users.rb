class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :username, null: false
      t.string :password_digest, null: false
      t.string :first_name
      t.string :last_name
      t.text :bio
      t.string :profile_image_url
      t.string :provider
      t.string :uid
      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :username, unique: true
    add_index :users, :provider
    add_index :users, :uid
  end
end
