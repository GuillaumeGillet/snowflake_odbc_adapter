# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters # :nodoc:
    module SnowflakeOdbc
      module SchemaStatements # :nodoc:
        # ODBC constants missing from Christian Werner's Ruby ODBC driver
        SQL_NO_NULLS = 0
        SQL_NULLABLE = 1
        SQL_NULLABLE_UNKNOWN = 2

        def data_sources
          tables | views
        end

        # Returns a Hash of mappings from the abstract data types to the native
        # database types. See TableDefinition#column for details on the recognized
        # abstract data types.
        def native_database_types
          @native_database_types ||= ::SnowflakeOdbcAdapter::ColumnMetadata.new(self).native_database_types
        end

        # Returns an array of table names, for database tables visible on the
        # current connection.
        def tables(_name = nil)
          stmt   = @raw_connection.tables
          result = stmt.fetch_all || []
          stmt&.drop
          result = ::SnowflakeOdbcAdapter::Snowflake.table_filter(result, @raw_connection)
          result.each_with_object([]) do |row, table_names|
            table_names << format_case(row[2])
          end
        end

        # Returns an array of view names, for database views visible on the
        # current connection.
        def views(_name = nil)
          stmt   = @raw_connection.tables
          result = stmt.fetch_all || []
          stmt&.drop
          result = ::SnowflakeOdbcAdapter::Snowflake.view_filter(result, @raw_connection)
          result.each_with_object([]) do |row, table_names|
            table_names << format_case(row[2])
          end
        end

        # Checks to see if the table +table_name+ exists on the database.
        #
        #   table_exists?(:developers)
        #
        def table_exists?(table_name)
          stmt = @raw_connection.tables(native_case(table_name.to_s))
          result = stmt.fetch_all || []
          stmt.drop
          result.size.positive?
        end

        def column_definitions(table_name)
          stmt = @raw_connection.columns(native_case(table_name.to_s))
          result = stmt.fetch_all || []
          stmt.drop
          # Column can return some technical columns
          ::SnowflakeOdbcAdapter::Snowflake.column_filters(result)
        end

        def new_column_from_field(table_name, field, _definitions)
          col_name = field[3]
          SnowflakeOdbc::Column.new(
            format_case(col_name), # SQLColumns: COLUMN_NAME,
            field[12], # SQLColumns: COLUMN_DEF,
            sql_type_metadata(field),
            nullability(field[17], field[10])
          )
        end

        def primary_key(table_name)
          stmt   = @raw_connection.primary_keys(native_case(table_name.to_s))
          result = stmt.fetch_all || []
          stmt&.drop
          result[0] && format_case(result[0][3])
        end

        def rename_table(table_name, new_name, **options)
          validate_table_length!(new_name) unless options[:_uses_legacy_table_name]
          clear_cache!
          schema_cache.clear_data_source_cache!(table_name.to_s)
          schema_cache.clear_data_source_cache!(new_name.to_s)
          execute "ALTER TABLE #{quote_table_name(table_name)} RENAME TO #{quote_table_name(new_name)}"
        end

        # Renames a column in a table.
        def rename_column(table_name, column_name, new_column_name) # :nodoc:
          clear_cache!
          execute("ALTER TABLE #{quote_table_name(table_name)} #{rename_column_sql(table_name, column_name,
                                                                                   new_column_name)}")
        end

        private

        def sql_type_metadata(col)
          col_scale       = col[8]  # SQLColumns: DECIMAL_DIGITS
          col_sql_type    = col[4]  # SQLColumns: DATA_TYPE
          col_limit       = col[6]  # SQLColumns: COLUMN_SIZE
          args = { sql_type: col_sql_type, type: col_sql_type, limit: col_limit }
          col_native_type = col[5]  # SQLColumns: TYPE_NAME
          args[:sql_type] = "boolean" if col_native_type == "BOOLEAN"
          args[:sql_type] = "json" if %w[VARIANT JSON STRUCT].include?(col_native_type)
          args[:sql_type] = "date" if col_native_type == "DATE"
          if [ ODBC::SQL_DECIMAL, ODBC::SQL_NUMERIC ].include?(col_sql_type)
            args[:scale]     = col_scale || 0
            args[:precision] = col_limit
          end
          ActiveRecord::ConnectionAdapters::SqlTypeMetadata.new(**args)
        end

        def native_case(identifier)
          if ::SnowflakeOdbcAdapter::Metadata.instance.upcase_identifiers?
            identifier =~ /[A-Z]/ ? identifier : identifier.upcase
          else
            identifier
          end
        end

        # Assume column is nullable if nullable == SQL_NULLABLE_UNKNOWN
        def nullability(is_nullable, nullable)
          not_nullable = !is_nullable || !nullable.to_s.match("NO").nil?
          !(not_nullable || nullable == SQL_NO_NULLS)
        end
      end
    end
  end
end
