# frozen_string_literal: true

SimpleCov.start

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "snowflake_odbc_adapter"

require "minitest/autorun"
