class AddDeferredFieldsToTodo < ActiveRecord::Migration[6.0]
  def change
    add_column :todos, :deferred_at, :datetime, precision: 6
    add_column :todos, :deferred_until, :datetime, precision: 6
  end
end
