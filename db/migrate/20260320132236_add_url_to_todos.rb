class AddUrlToTodos < ActiveRecord::Migration[8.1]
  def change
    add_column :todos, :url, :string
  end
end
