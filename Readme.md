[![Build Status](https://travis-ci.org/EagerELK/ditty.svg?branch=master)](https://travis-ci.org/EagerELK/ditty)
[![Code Climate](https://codeclimate.com/github/EagerELK/ditty/badges/gpa.svg)](https://codeclimate.com/github/EagerELK/ditty)
[![Test Coverage](https://codeclimate.com/github/EagerELK/ditty/badges/coverage.svg)](https://codeclimate.com/github/EagerELK/ditty/coverage)

# Ditty

Ditty provides an extra layer of functionality on top of [Sinatra](http://sinatrarb.com/) to give structure and basic tools to an already great framework. You can get a new application, with user authentication and basic CRUD / REST interfaces, up and running in minutes.

## Installation

Add these lines to your application's Gemfile:

```ruby
gem 'ditty'
gem 'sqlite3'
```

You can replace `sqlite3` with a DB adapter of your choice.

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install ditty
```

## Usage

1. Add the components to your rack config file. See the included [`config.ru`](https://github.com/EagerELK/ditty/blob/master/config.ru) file for an example setup
2. Set the DB connection as the `DATABASE_URL` ENV variable: `DATABASE_URL=sqlite://development.db`
3. Run the Ditty migrations: `bundle exec ditty migrate`
4. Run the Ditty server: `bundle exec ditty server`

## Components

The application can now be further extended by creating components.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/EagerELK/ditty.

## License

The Ditty gem is an Open Source project licensed under the terms of
the MIT license.  Please see [MIT license](License.txt)
for license text.
