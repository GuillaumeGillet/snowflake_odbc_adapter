# SnowflakeOdbcAdapter

Based on the [odbc_adpter](https://github.com/localytics/odbc_adapter) that seems to not been maintain since rails 5.1. And despite the [fork](https://github.com/singlespot/odbc_adapter) we made to follow the rails evolution.
We decide to create a new gem, dedicated to connect with the Snowflake odbc driver.

This Gem is in a very early development

## Installation

In your Gemfile add the two dependencies

```
gem 'snowflake_odbc_adapter'
gem 'ruby-odbc', :git => 'https://github.com/vhermecz/ruby-odbc.git', branch: 'main'
```

We had use a fork of *ruby-odbc* as the original gem is not maintain anymore and so, no compatible with ruby 3 or above

## Usage

Right now the connection only work using a connection string

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/snowflake_odbc_adapter. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/snowflake_odbc_adapter/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SnowflakeOdbcAdapter project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/snowflake_odbc_adapter/blob/master/CODE_OF_CONDUCT.md).
