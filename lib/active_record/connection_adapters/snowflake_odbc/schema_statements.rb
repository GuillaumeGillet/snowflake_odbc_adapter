# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters # :nodoc:
    module SnowflakeOdbc
      module SchemaStatements # :nodoc:
        # ODBC constants missing from Christian Werner's Ruby ODBC driver
        SQL_NO_NULLS = 0
        SQL_NULLABLE = 1
        SQL_NULLABLE_UNKNOWN = 2

        # Returns a Hash of mappings from the abstract data types to the native
        # database types. See TableDefinition#column for details on the recognized
        # abstract data types.
        # def native_database_types
        #   @native_database_types ||= ColumnMetadata.new(self).native_database_types
        # end

        def data_sources
          tables
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
          stmt.drop

          result.each_with_object([]) do |row, table_names|
            table_names << format_case(row[2])
          end
        end

        def column_definitions(table_name)
          stmt   = @raw_connection.columns(native_case(table_name.to_s))
          result = stmt.fetch_all || []
          stmt.drop
          result
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
          result[0] && result[0][3]
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
          if [ODBC::SQL_DECIMAL, ODBC::SQL_NUMERIC].include?(col_sql_type)
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
