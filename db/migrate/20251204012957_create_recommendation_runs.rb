class CreateRecommendationRuns < ActiveRecord::Migration[7.1]
  def change
    create_table :recommendation_runs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.json :movies, null: false, default: []
      t.string :job_id
      t.text :error_message
      t.datetime :completed_at

      t.timestamps
    end
  end
end