class AddNotesToTodos < ActiveRecord::Migration[6.0]
  def change
    add_column :todos, :notes, :text
  end
end
