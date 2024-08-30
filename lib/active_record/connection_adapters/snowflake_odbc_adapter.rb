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
      end

      def initialize(...)
        super
        @raw_connection, @config = self.class.new_client(@config)
        @raw_connection.use_time = true
        ::SnowflakeOdbcAdapter::Metadata.instance.connection(@config, @raw_connection)
      end

      def reconnect
        @raw_connection, @config = self.class.new_client(@config)
      end
    end
    register "odbc", "ActiveRecord::ConnectionAdapters::SnowflakeOdbcAdapter", "active_record/connection_adapters/snowflake_odbc_adapter"
  end
end