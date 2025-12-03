# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_03_043412) do
  create_table "diary_entries", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "mood"
    t.integer "movie_id", null: false
    t.integer "rating", default: 0
    t.boolean "rewatch", default: false, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.date "watched_date"
    t.index ["movie_id"], name: "index_diary_entries_on_movie_id"
    t.index ["rewatch"], name: "index_diary_entries_on_rewatch"
    t.index ["user_id", "movie_id"], name: "index_diary_entries_on_user_id_and_movie_id"
    t.index ["user_id", "watched_date"], name: "index_diary_entries_on_user_id_and_watched_date"
    t.index ["user_id"], name: "index_diary_entries_on_user_id"
    t.index ["watched_date"], name: "index_diary_entries_on_watched_date"
  end

  create_table "favorites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "movie_id", null: false
    t.integer "top_position"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["movie_id"], name: "index_favorites_on_movie_id"
    t.index ["user_id", "movie_id"], name: "index_favorites_on_user_id_and_movie_id", unique: true
    t.index ["user_id", "top_position"], name: "index_favorites_on_user_id_and_top_position", unique: true, where: "top_position IS NOT NULL"
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "follows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "followed_id", null: false
    t.integer "follower_id", null: false
    t.string "status", default: "accepted", null: false
    t.datetime "updated_at", null: false
    t.index ["followed_id"], name: "index_follows_on_followed_id"
    t.index ["follower_id", "followed_id"], name: "index_follows_on_follower_id_and_followed_id", unique: true
    t.index ["follower_id"], name: "index_follows_on_follower_id"
  end

  create_table "movie_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "movie_id", null: false
    t.integer "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["movie_id", "tag_id"], name: "index_movie_tags_on_movie_id_and_tag_id", unique: true
    t.index ["movie_id"], name: "index_movie_tags_on_movie_id"
    t.index ["tag_id"], name: "index_movie_tags_on_tag_id"
  end

  create_table "movies", force: :cascade do |t|
    t.string "backdrop_url"
    t.text "cast", default: "[]"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "director"
    t.text "genres", default: "[]"
    t.string "poster_url"
    t.date "release_date"
    t.integer "runtime"
    t.string "title", null: false
    t.integer "tmdb_id"
    t.datetime "updated_at", null: false
    t.float "vote_average"
    t.integer "vote_count"
    t.index ["release_date"], name: "index_movies_on_release_date"
    t.index ["title"], name: "index_movies_on_title"
    t.index ["tmdb_id"], name: "index_movies_on_tmdb_id", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "notifiable_id", null: false
    t.string "notifiable_type", null: false
    t.string "notification_type", null: false
    t.boolean "read", default: false, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "ratings", force: :cascade do |t|
    t.boolean "contains_spoilers", default: false, null: false
    t.datetime "created_at", null: false
    t.integer "movie_id", null: false
    t.text "review"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "value"
    t.index ["movie_id"], name: "index_ratings_on_movie_id"
    t.index ["user_id", "movie_id"], name: "index_ratings_on_user_id_and_movie_id", unique: true
    t.index ["user_id"], name: "index_ratings_on_user_id"
    t.index ["value"], name: "index_ratings_on_value"
  end

  create_table "review_reactions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "emoji", default: "👍", null: false
    t.integer "rating_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["rating_id", "user_id", "emoji"], name: "index_review_reactions_on_rating_id_and_user_id_and_emoji", unique: true
    t.index ["rating_id"], name: "index_review_reactions_on_rating_id"
    t.index ["user_id"], name: "index_review_reactions_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "category", default: "general"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "parent_category"
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_tags_on_category"
    t.index ["name"], name: "index_tags_on_name", unique: true
    t.index ["parent_category"], name: "index_tags_on_parent_category"
  end

  create_table "users", force: :cascade do |t|
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "first_name"
    t.boolean "is_private", default: false, null: false
    t.string "last_name"
    t.string "password_digest", null: false
    t.string "profile_image_url"
    t.string "provider"
    t.text "top_5_movies"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider"], name: "index_users_on_provider"
    t.index ["uid"], name: "index_users_on_uid"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "watchlists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "movie_id", null: false
    t.string "status", default: "to_watch"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["movie_id"], name: "index_watchlists_on_movie_id"
    t.index ["status"], name: "index_watchlists_on_status"
    t.index ["user_id", "movie_id"], name: "index_watchlists_on_user_id_and_movie_id", unique: true
    t.index ["user_id"], name: "index_watchlists_on_user_id"
  end

  add_foreign_key "diary_entries", "movies"
  add_foreign_key "diary_entries", "users"
  add_foreign_key "favorites", "movies"
  add_foreign_key "favorites", "users"
  add_foreign_key "follows", "users", column: "followed_id"
  add_foreign_key "follows", "users", column: "follower_id"
  add_foreign_key "movie_tags", "movies"
  add_foreign_key "movie_tags", "tags"
  add_foreign_key "notifications", "users"
  add_foreign_key "ratings", "movies"
  add_foreign_key "ratings", "users"
  add_foreign_key "review_reactions", "ratings"
  add_foreign_key "review_reactions", "users"
  add_foreign_key "watchlists", "movies"
  add_foreign_key "watchlists", "users"
end
