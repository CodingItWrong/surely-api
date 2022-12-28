# frozen_string_literal: true

namespace :purge do
  task josh: [:environment] do
    josh_email = "josh@joshjustice.com"
    completed_day_limit = 30

    josh = User.find_by(email: josh_email)

    deleted_todos = josh.todos.status(:deleted)
    old_completed_todos = josh.todos.status(:completed).where("completed_at < ?", completed_day_limit.days.ago)

    deleted_todos_count = deleted_todos.count
    old_completed_todos_count = old_completed_todos.count

    deleted_todos.destroy_all
    old_completed_todos.destroy_all

    puts "Purged todos for #{josh_email}: #{deleted_todos_count} deleted todos, #{old_completed_todos_count} completed todos older than #{completed_day_limit} days."
  end
end
