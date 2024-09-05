# frozen_string_literal: true

module SnowflakeOdbcAdapter
  # Snowflake specific overrides
  module Snowflake
    PRIMARY_KEY = "NUMBER UNIQUE PRIMARY KEY AUTOINCREMENT START 1 INCREMENT 1 ORDER "
    class << self
      # Remove Snowflake specific columns
      def column_filters(columns)
        columns.reject { |col| col[0] =~ /^snowflake$/i }.reject { |col| col[1] =~ /^account_usage$/i }
      end
    end
  end
end
