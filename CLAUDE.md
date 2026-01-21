# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Surely is a JSON:API-compliant Rails 8 backend for a todo app. The API uses:
- **JSON:API Resources gem** for JSON:API formatting (currently being migrated away from)
- **Doorkeeper** for OAuth 2.0 authentication (password grant flow)
- **PostgreSQL** with UUID primary keys
- **RSpec** for testing

The API serves the [surely-expo](https://github.com/CodingItWrong/surely-expo) React Native frontend.

## Commands

### Setup
```bash
bundle install
rails db:setup
```

### Running the Server
```bash
bin/serve                           # Starts Rails server on 0.0.0.0:3000
rails s -b 0.0.0.0                 # Equivalent alternative
```

### Testing
```bash
bin/rspec                           # Run all tests
bin/rspec spec/requests/todos_spec.rb  # Run specific test file
bin/rspec spec/requests/todos_spec.rb:8  # Run test at specific line
```

### Code Quality
```bash
bundle exec standardrb              # Run Ruby style linter
bundle exec standardrb --fix        # Auto-fix style issues
```

### Database
```bash
rails db:migrate                    # Run pending migrations
rails db:rollback                   # Rollback last migration
rails db:reset                      # Drop, create, migrate, and seed
```

### Generators (for JSON:API Resources pattern)
```bash
rails generate model widget [fields]
rails generate jsonapi:resource widget
rails generate jsonapi:controller widget
```

## Architecture

### Data Model
- **Users**: Has many todos and categories. Uses `bcrypt` for password hashing.
- **Todos**: Belongs to user and optionally to category. Uses soft deletion pattern (no hard delete). Key attributes:
  - `completed_at`, `deleted_at` (datetime): Determines status
  - `deferred_until` (date): For "tomorrow" and "future" todos
  - `name`, `notes` (string)
- **Categories**: Belongs to user, has many todos. Auto-assigns `sort_order` on creation. Supports hard deletion.

### Status Filtering Logic
Todos don't have a `status` column. Status is computed from attributes:
- **available**: `completed_at` null, `deleted_at` null, `deferred_until` null or past
- **tomorrow**: `deferred_until` is tomorrow
- **future**: `deferred_until` is after tomorrow
- **completed**: `completed_at` not null
- **deleted**: `deleted_at` not null

This logic is implemented in [app/models/todo.rb:9-24](app/models/todo.rb#L9-L24) via scopes.

### Authentication
- Uses Doorkeeper OAuth 2.0 with password grant flow
- Token endpoint: `POST /oauth/token` (not JSON:API format, uses regular JSON)
- All JSON:API endpoints require Bearer token except user signup
- Current user extracted from Doorkeeper token in [app/controllers/application_controller.rb:14-18](app/controllers/application_controller.rb#L14-L18)
- Access tokens never expire (`access_token_expires_in nil`)

### JSON:API Implementation
Currently uses `jsonapi-resources` gem but is migrating away (see [docs/API_ENDPOINT_MIGRATION_PLAN.md](docs/API_ENDPOINT_MIGRATION_PLAN.md)).

Key patterns:
- **Content-Type**: All requests/responses use `application/vnd.api+json`
- **Attribute naming**: Database `snake_case` → JSON:API `kebab-case` (e.g., `completed_at` → `completed-at`)
- **Resource scoping**: Resources always scoped to authenticated user via `current_user` context
- **UUID keys**: Configured in [config/initializers/jsonapi.rb:6](config/initializers/jsonapi.rb#L6)
- **Relationships**: Todos support `include=category` query parameter to sideload categories
- **Pagination**: Uses custom `optional_paged` paginator. Only completed/deleted todos paginate. Includes `meta.page-count` in responses.
- **Filtering**: Custom filters implemented in resource classes (e.g., `filter[status]`, `filter[search]`)

### Controllers & Resources Pattern
Controllers inherit from `ApplicationController` which includes `JSONAPI::ActsAsResourceController`:
- [app/controllers/todos_controller.rb](app/controllers/todos_controller.rb)
- [app/controllers/categories_controller.rb](app/controllers/categories_controller.rb)
- [app/controllers/users_controller.rb](app/controllers/users_controller.rb)

Resources define attributes, relationships, filters, and authorization:
- [app/resources/todo_resource.rb](app/resources/todo_resource.rb) - See filters and field permissions
- [app/resources/category_resource.rb](app/resources/category_resource.rb)
- [app/resources/user_resource.rb](app/resources/user_resource.rb)
- [app/resources/application_resource.rb](app/resources/application_resource.rb) - Base class with `current_user` helper

### Routes
Routes use `jsonapi_resources` helper (see [config/routes.rb](config/routes.rb)):
```ruby
jsonapi_resources :todos           # Full CRUD except DELETE
jsonapi_resources :categories      # Full CRUD including DELETE
jsonapi_resources :users, only: %w[create]  # Signup only
use_doorkeeper                     # OAuth endpoints
```

### Testing Strategy
Tests live in `spec/requests/` with shared contexts in `spec/support/`:
- [spec/support/with_a_logged_in_user.rb](spec/support/with_a_logged_in_user.rb) - Auth helper for tests
- [spec/support/factory_bot.rb](spec/support/factory_bot.rb) - Factory configuration
- Tests use FactoryBot factories from `spec/factories/`

When writing tests for JSON:API endpoints, always verify:
- Response status codes
- Content-Type header (`application/vnd.api+json`)
- JSON:API structure (`data`, `attributes`, `relationships`, `included`)
- User scoping (can't access other users' resources)
- Attribute name transformation (kebab-case)

### Configuration Notes
- **CORS**: Wide open (`origins "*"`) - see [config/initializers/cors.rb](config/initializers/cors.rb)
- **Ruby version**: 3.4.5 (see [.ruby-version](.ruby-version))
- **Rails version**: 8.0.3
- **Database**: PostgreSQL with databases `surely_development`, `surely_test`, `surely_production`

## Current Migration Work

The codebase is actively migrating away from the `jsonapi-resources` gem to custom JSON:API implementation. See [docs/API_ENDPOINT_MIGRATION_PLAN.md](docs/API_ENDPOINT_MIGRATION_PLAN.md) for the full plan.

**Migration process (DO NOT deviate)**:
1. **Phase 1**: Write comprehensive tests for existing behavior (tests must pass with current library)
2. **Phase 2**: Reimplement controller without library helpers (verify all tests still pass)

When working on this migration, follow the test coverage requirements in the migration plan document.

## API Endpoints Reference

See [docs/API_ENDPOINTS.md](docs/API_ENDPOINTS.md) for complete endpoint documentation including:
- Request/response formats
- Query parameters (`filter[status]`, `filter[search]`, `sort`, `page[number]`, `include`)
- Authentication requirements
- Special behaviors (soft delete, status filtering, relationship sideloading)
