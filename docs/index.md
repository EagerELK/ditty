# Ditty.io

Ditty is a Web Application Framework built on top of the [Sinatra](http://sinatrarb.com/) framework.

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
3. Prepare the Ditty folder: `bundle exec ditty prep`
3. Run the Ditty migrations: `bundle exec ditty migrate`
4. Run the Ditty server: `bundle exec ditty server`
