class CreateCategories < ActiveRecord::Migration[6.0]
  def change
    create_table :categories, id: :uuid do |t|
      t.string :name, null: false
      t.integer :sort_order
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
