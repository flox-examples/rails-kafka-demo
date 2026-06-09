ActiveRecord::Schema[7.2].define(version: 2024_01_01_000001) do
  enable_extension "plpgsql"

  create_table "posts", force: :cascade do |t|
    t.string "title", null: false
    t.text "body", null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_posts_on_created_at"
    t.index ["status"], name: "index_posts_on_status"
  end
end
