class CreateBlogs < ActiveRecord::Migration[7.0]
  def change
    create_table :blogs do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.string :tags
      t.datetime :published_at

      t.timestamps
    end

    add_index :blogs, :published_at
    add_index :blogs, :created_at
  end
end
