class CreateArticles < ActiveRecord::Migration[5.1]
  def change
    create_table :articles do |t|
      t.string :name
      t.references :author, foreign_key: true

      t.timestamps
    end
  end
end
