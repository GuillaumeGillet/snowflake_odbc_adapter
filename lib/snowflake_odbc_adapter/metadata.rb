# frozen_string_literal: true

require "singleton"

module SnowflakeOdbcAdapter
  class Metadata # :nodoc:
    include Singleton

    FIELDS = %i[
      SQL_DBMS_NAME
      SQL_DBMS_VER
      SQL_IDENTIFIER_CASE
      SQL_QUOTED_IDENTIFIER_CASE
      SQL_IDENTIFIER_QUOTE_CHAR
      SQL_MAX_IDENTIFIER_LEN
      SQL_MAX_TABLE_NAME_LEN
      SQL_USER_NAME
      SQL_DATABASE_NAME
    ].freeze

    attr_reader :identifier_quote_char

    def initialize
      @mutex = Mutex.new
    end

    FIELDS.each do |field|
      define_method(field.to_s.downcase.gsub("sql_", "")) do
        metadata[field]
      end
    end

    def upcase_identifiers?
      (identifier_case == ODBC::SQL_IC_UPPER)
    end

    def connection(config, connection)
      unless @connection
        with_mutex do
          @connection = connection
        end
      end
      @connection
    end

    private

    def metadata
      raise "Need to connect" unless @connection

      unless @metadata
        with_mutex do
          @metadata = Hash[FIELDS.map do |field|
            info = @connection.get_info(ODBC.const_get(field))
            [ field, info ]
          end]
        end
      end
      @metadata
    end

    def with_mutex(&block)
      @mutex.synchronize(&block)
    end
  end
end
