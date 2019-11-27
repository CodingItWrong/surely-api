class CreateTodos < ActiveRecord::Migration[6.0]
  def change
    create_table :todos, id: :uuid do |t|
      t.string :name
      t.references :user

      t.timestamps
    end
  end
end
