# frozen_string_literal: true

require_relative "lib/snowflake_odbc_adapter/version"

Gem::Specification.new do |spec|
  spec.name = "snowflake_odbc_adapter"
  spec.version = SnowflakeOdbcAdapter::VERSION
  spec.authors = [ "Guillaume GILLET" ]
  spec.email = [ "guillaume.gillet@singlespot.com" ]

  spec.summary = "ODBC ActiveRecord adapter design for Snowflake"
  spec.description = <<~TXT
    As the generic odbc adapter https://github.com/localytics/odbc_adapter is no longer maintain and
    do not follow the rails evolution, we need to create our own.
  TXT
  spec.homepage = "https://github.com/singlespot/snowflake_odbc_adapter"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/GuillaumeGillet/snowflake_odbc_adapter"
  spec.metadata["changelog_uri"] = "https://github.com/GuillaumeGillet/snowflake_odbc_adapter/CHANGELOG.md."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = [ "lib" ]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "activerecord", ">= 7.2"
  spec.add_dependency "ruby-odbc"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
