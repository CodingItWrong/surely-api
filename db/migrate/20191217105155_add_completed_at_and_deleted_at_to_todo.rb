class AddCompletedAtAndDeletedAtToTodo < ActiveRecord::Migration[6.0]
  def change
    add_column :todos, :completed_at, :datetime, precision: 6
    add_column :todos, :deleted_at, :datetime, precision: 6
  end
end
