# frozen_string_literal: true
user = User.create!(email: 'example@example.com', password: 'password')

# available
user.todos.create!(
  name: 'Yesterday Todo',
  created_at: 3.days.ago,
  deferred_until: 1.day.ago,
  deferred_at: 2.days.ago,
)
user.todos.create!(
  name: 'Simple Todo',
  created_at: 1.day.ago,
)

# completed
user.todos.create!(
  name: 'Completed Old Todo',
  created_at: 2.weeks.ago,
  completed_at: 1.week.ago,
)
user.todos.create!(
  name: 'Completed Today Todo',
  created_at: 1.day.ago,
  completed_at: 1.hour.ago,
)

# deleted
user.todos.create!(
  name: 'Deleted Old Todo',
  created_at: 2.weeks.ago,
  deleted_at: 1.week.ago,
)
user.todos.create!(
  name: 'Deleted Todo',
  created_at: 2.days.ago,
  deleted_at: 1.day.ago,
)

# deferred
user.todos.create!(
  name: 'Next Week Todo',
  created_at: 1.day.ago,
  deferred_until: 1.week.from_now,
  deferred_at: 1.hour.ago,
)
user.todos.create!(
  name: 'Tomorrow Todo',
  created_at: 1.day.ago,
  deferred_until: 1.day.from_now,
  deferred_at: 1.hour.ago,
)
