# frozen_string_literal: true

user = User.create!(email: "example@example.com", password: "password")

# categories
work = user.categories.create!(name: "Work", sort_order: 0)
after_work = user.categories.create!(name: "After Work", sort_order: 1)

# available
user.todos.create!(
  name: "Submit time sheet",
  category: work
)
user.todos.create!(
  name: "Clean up the house",
  notes: "Clean off countertops, pick up kids' toys",
  category: after_work,
  deferred_until: 0.days.ago,
  deferred_at: 2.days.ago
)
user.todos.create!(
  name: "Get groceries",
  category: after_work
)

# completed
user.todos.create!(
  name: "Completed Old Todo",
  created_at: 2.weeks.ago,
  completed_at: 1.week.ago
)
user.todos.create!(
  name: "Completed Today Todo",
  created_at: 1.day.ago,
  completed_at: 1.hour.ago
)

# deleted
user.todos.create!(
  name: "Deleted Old Todo",
  created_at: 2.weeks.ago,
  deleted_at: 1.week.ago
)
user.todos.create!(
  name: "Deleted Todo",
  created_at: 2.days.ago,
  deleted_at: 1.day.ago
)

# deferred
user.todos.create!(
  name: "Next Week Todo",
  created_at: 1.day.ago,
  deferred_until: 1.week.from_now,
  deferred_at: 1.hour.ago
)
user.todos.create!(
  name: "Tomorrow Todo",
  created_at: 1.day.ago,
  deferred_until: 1.day.from_now,
  deferred_at: 1.hour.ago
)

# lots more todos
50.times { |i| user.todos.create!(name: "Completed #{i}", completed_at: i.days.ago) }
50.times { |i| user.todos.create!(name: "Deleted #{i}", deleted_at: i.days.ago) }
