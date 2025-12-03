class AddTop5MoviesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :top_5_movies, :text
  end
end
