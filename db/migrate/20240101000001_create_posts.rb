class CreatePosts < ActiveRecord::Migration[7.2]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.text :body, null: false
      t.string :status, null: false, default: "pending"
      t.timestamps
    end

    add_index :posts, :status
    add_index :posts, :created_at
  end
end
