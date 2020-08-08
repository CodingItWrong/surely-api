class AddCategoryToTodos < ActiveRecord::Migration[6.0]
  def change
    add_reference :todos, :category, type: :uuid, null: true, foreign_key: true
  end
end
