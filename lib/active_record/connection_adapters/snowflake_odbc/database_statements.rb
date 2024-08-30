module ActiveRecord
  module ConnectionAdapters # :nodoc:
    module SnowflakeOdbc
      module DatabaseStatements
        def internal_exec_query(sql, name = "SQL", binds = [], prepare: false, async: false, allow_retry: false) # :nodoc:
          log(sql, name, binds) do |notification_payload|
            if prepare
              stmt = @raw_connection.prepare(sql)
              binds.each_with_index do |bind, i|
                stmt.param_type(i, ODBC::SQL_INTEGER) if bind.value.is_a?(Integer)
                stmt.execute(*binds.map(&:value_for_database))
              end
            else
              stmt = @raw_connection.run(sql)
            end
            columns = stmt.columns
            values  = stmt.to_a
            stmt.drop
            notification_payload[:row_count] = values.count
            column_names = columns.keys.map { |key| format_case(key) }
            ActiveRecord::Result.new(column_names, values)
          end
        end

        def bind_params(binds, sql)
          prepared_binds = *prepared_binds(binds)
          prepared_binds.each.with_index(1) do |val, ind|
            sql = sql.gsub("$#{ind}", "'#{val}'")
          end
          sql
        end

        def prepared_binds(binds)
          binds.map(&:value_for_database)
        end

        protected

        # Build the type map for ActiveRecord
        # Here, ODBC and ODBC_UTF8 constants are interchangeable
        def initialize_type_map(map)
          map.register_type "boolean",              Type::Boolean.new
          map.register_type "json",                 Type::Json.new
          map.register_type ODBC::SQL_CHAR,         Type::String.new
          map.register_type ODBC::SQL_LONGVARCHAR,  Type::Text.new
          map.register_type ODBC::SQL_TINYINT,      Type::Integer.new(limit: 4)
          map.register_type ODBC::SQL_SMALLINT,     Type::Integer.new(limit: 8)
          map.register_type ODBC::SQL_INTEGER,      Type::Integer.new(limit: 16)
          map.register_type ODBC::SQL_BIGINT,       Type::BigInteger.new(limit: 32)
          map.register_type ODBC::SQL_REAL,         Type::Float.new(limit: 24)
          map.register_type ODBC::SQL_FLOAT,        Type::Float.new
          map.register_type ODBC::SQL_DOUBLE,       Type::Float.new(limit: 53)
          map.register_type ODBC::SQL_DECIMAL,      Type::Float.new
          map.register_type ODBC::SQL_NUMERIC,      Type::Integer.new
          map.register_type ODBC::SQL_BINARY,       Type::Binary.new
          map.register_type ODBC::SQL_DATE,         Type::Date.new
          map.register_type ODBC::SQL_DATETIME,     Type::DateTime.new
          map.register_type ODBC::SQL_TIME,         Type::Time.new
          map.register_type ODBC::SQL_TIMESTAMP,    Type::DateTime.new
          map.register_type ODBC::SQL_GUID,         Type::String.new

          alias_type map, ODBC::SQL_BIT,            "boolean"
          alias_type map, ODBC::SQL_VARCHAR,        ODBC::SQL_CHAR
          alias_type map, ODBC::SQL_WCHAR,          ODBC::SQL_CHAR
          alias_type map, ODBC::SQL_WVARCHAR,       ODBC::SQL_CHAR
          alias_type map, ODBC::SQL_WLONGVARCHAR,   ODBC::SQL_LONGVARCHAR
          alias_type map, ODBC::SQL_VARBINARY,      ODBC::SQL_BINARY
          alias_type map, ODBC::SQL_LONGVARBINARY,  ODBC::SQL_BINARY
          alias_type map, ODBC::SQL_TYPE_DATE,      ODBC::SQL_DATE
          alias_type map, ODBC::SQL_TYPE_TIME,      ODBC::SQL_TIME
          alias_type map, ODBC::SQL_TYPE_TIMESTAMP, ODBC::SQL_TIMESTAMP
        end

        private

        # Can't use the built-in ActiveRecord map#alias_type because it doesn't
        # work with non-string keys, and in our case the keys are (almost) all
        # numeric
        def alias_type(map, new_type, old_type)
          map.register_type(new_type) do |_, *args|
            map.lookup(old_type, *args)
          end
        end

        def raw_execute(sql, name, async: false, allow_retry: false, materialize_transactions: true)
          @raw_connection.do(sql)
        end

        # Assume received identifier is in DBMS's data dictionary case.
        def format_case(identifier)
          if ::SnowflakeOdbcAdapter::Metadata.instance.upcase_identifiers?
            identifier =~ /[a-z]/ ? identifier : identifier.downcase
          else
            identifier
          end
        end
      end
    end
  end
end
