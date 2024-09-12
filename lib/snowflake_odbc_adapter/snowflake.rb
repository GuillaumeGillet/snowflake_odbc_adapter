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

      # Remove outside database tables
      def table_filter(tables, connection)
        database = connection.get_info(ODBC::SQL_DATABASE_NAME)
        tables.select { |table| table[0] == database && table[3] =~ /^TABLE$/i }
      end

      # Remove outside database views
      def view_filter(tables, connection)
        database = connection.get_info(ODBC::SQL_DATABASE_NAME)
        tables.select do |table|
          table[0] == database && table[3] =~ /^VIEW$/i && table[1] !~ /^information_schema$/i
        end
      end
    end
  end
end
