# Surely

Official backend for the Surely todo app. A JSON:API-compliant web service implmented in Ruby on Rails.

The official frontend is [surely-expo](https://github.com/CodingItWrong/surely-expo). If you'd like to host your own backend, you will need to make your own build of the client to point to it.

## Requirements

1. Ruby 3.0.2
1. PostgreSQL (e.g. [Postgres.app][postgres-app])

## Installation

```sh
$ bundle install
$ rails db:setup
```

## Running

```bash
$ bin/serve
```

## Development

To generate models, resources, and controllers:

```bash
$ rails generate model widget [fields]
$ rails generate jsonapi:resource widget
$ rails generate jsonapi:controller widget
```

## Testing

```sh
$ bin/rspec
```

## Release

[Heroku](https://www.heroku.com/) is a good backend hosting option.

[postgres-app]: http://postgresapp.com

## License

MIT
