# frozen_string_literal: true

require 'active_record'
require 'active_record/connection_adapters/abstract_adapter'
require "active_record/connection_adapters/snowflake_odbc/quoting"
require "active_record/connection_adapters/snowflake_odbc/database_statements"
require "active_record/connection_adapters/snowflake_odbc/schema_statements"
require "active_record/connection_adapters/snowflake_odbc/column"
require "snowflake_odbc_adapter/metadata"
require "snowflake_odbc_adapter/column_metadata"
require 'odbc'
require 'odbc_utf8'

module ActiveRecord
  module ConnectionAdapters
    class SnowflakeOdbcAdapter < AbstractAdapter
      ADAPTER_NAME = "ODBC"

      include SnowflakeOdbc::Quoting
      include SnowflakeOdbc::DatabaseStatements
      include SnowflakeOdbc::SchemaStatements

      class << self

        def new_client(config)
          config = config.symbolize_keys
          _, config = if config.key?(:dsn)
            dsn_connection(config)
          elsif config.key?(:conn_str)
            str_connection(config)
          else
            raise ArgumentError, 'No data source name (:dsn) or connection string (:conn_str) specified.'
          end
        rescue ::ODBC::Error => error
          #TODO: be more specific on error to raise 
          raise ActiveRecord::ConnectionNotEstablished, error.message
        end

        def dbconsole(config, options = {})
          raise NotImplementedError
        end

        private
        def dsn_connection(config)
          raise NotImplementedError
        end

        def str_connection(config)
          attrs = config[:conn_str].split(';').map { |option| option.split('=', 2) }.to_h
          odbc_module = attrs['ENCODING'] == 'utf8' ? ODBC_UTF8 : ODBC
          driver = odbc_module::Driver.new
          driver.name = 'odbc'
          driver.attrs = attrs
          connection = odbc_module::Database.new.drvconnect(driver)
          # encoding_bug indicates that the driver is using non ASCII and has the issue referenced here https://github.com/larskanis/ruby-odbc/issues/2
          [connection, config.merge(driver: driver, encoding: attrs['ENCODING'], encoding_bug: attrs['ENCODING'] == 'utf8')]
        end


        def initialize_type_map(m)
          super(m)
          #Integer are negated by active record
          m.register_type (-1 * ODBC::SQL_TIMESTAMP),    Type::DateTime.new
          m.register_type "boolean",                     Type::Boolean.new
          m.register_type "json",                        Type::Json.new
          m.register_type (-1 * ODBC::SQL_CHAR),         Type::String.new
          m.register_type (-1 * ODBC::SQL_LONGVARCHAR),  Type::Text.new
          m.register_type (-1 * ODBC::SQL_TINYINT),      Type::Integer.new(limit: 4)
          m.register_type (-1 * ODBC::SQL_SMALLINT),     Type::Integer.new(limit: 8)
          m.register_type (-1 * ODBC::SQL_INTEGER),      Type::Integer.new(limit: 16)
          m.register_type (-1 * ODBC::SQL_BIGINT),       Type::BigInteger.new(limit: 32)
          m.register_type (-1 * ODBC::SQL_REAL),         Type::Float.new(limit: 24)
          m.register_type (-1 * ODBC::SQL_FLOAT),        Type::Float.new
          m.register_type (-1 * ODBC::SQL_DOUBLE),       Type::Float.new(limit: 53)
          m.register_type (-1 * ODBC::SQL_DECIMAL),      Type::Float.new
          m.register_type (-1 * ODBC::SQL_NUMERIC),      Type::Integer.new
          m.register_type (-1 * ODBC::SQL_BINARY),       Type::Binary.new
          m.register_type (-1 * ODBC::SQL_DATE),         Type::Date.new
          m.register_type (-1 * ODBC::SQL_DATETIME),     Type::DateTime.new
          m.register_type (-1 * ODBC::SQL_TIME),         Type::Time.new
          m.register_type (-1 * ODBC::SQL_TIMESTAMP),    Type::DateTime.new
          m.register_type (-1 * ODBC::SQL_GUID),         Type::String.new

          alias_type m, (-1 * ODBC::SQL_BIT),            "boolean"
          alias_type m, (-1 * ODBC::SQL_VARCHAR),        (-1 * ODBC::SQL_CHAR)
          alias_type m, (-1 * ODBC::SQL_WCHAR),          (-1 * ODBC::SQL_CHAR)
          alias_type m, (-1 * ODBC::SQL_WVARCHAR),       (-1 * ODBC::SQL_CHAR)
          alias_type m, (-1 * ODBC::SQL_WLONGVARCHAR),   (-1 * ODBC::SQL_LONGVARCHAR)
          alias_type m, (-1 * ODBC::SQL_VARBINARY),      (-1 * ODBC::SQL_BINARY)
          alias_type m, (-1 * ODBC::SQL_LONGVARBINARY),  (-1 * ODBC::SQL_BINARY)
          alias_type m, (-1 * ODBC::SQL_TYPE_DATE),      (-1 * ODBC::SQL_DATE)
          alias_type m, (-1 * ODBC::SQL_TYPE_TIME),      (-1 * ODBC::SQL_TIME)
          alias_type m, (-1 * ODBC::SQL_TYPE_TIMESTAMP), (-1 * ODBC::SQL_TIMESTAMP)
        end

        # Can't use the built-in ActiveRecord map#alias_type because it doesn't
        # work with non-string keys, and in our case the keys are (almost) all
        # numeric
        def alias_type(map, new_type, old_type)
          map.register_type(new_type) do |_, *args|
            map.lookup(old_type, *args)
          end
        end
      end

      TYPE_MAP = Type::TypeMap.new.tap { |m| initialize_type_map(m) }

      def initialize(...)
        super
        @raw_connection, @config = self.class.new_client(@config)
        @raw_connection.use_time = true
        ::SnowflakeOdbcAdapter::Metadata.instance.connection(@config, @raw_connection)
      end

      def supports_insert_returning?
        false
      end

      def active?
        @raw_connection.connected?
      end

      def reconnect
        @raw_connection, @config = self.class.new_client(@config)
      end
    end
    register "odbc", "ActiveRecord::ConnectionAdapters::SnowflakeOdbcAdapter", "active_record/connection_adapters/snowflake_odbc_adapter"
  end
end