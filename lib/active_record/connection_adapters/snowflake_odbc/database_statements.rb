module ActiveRecord
  module ConnectionAdapters # :nodoc:
    module SnowflakeOdbc
      module DatabaseStatements
        # Have to because of create table
        def prepared_statements
          true
        end

        def internal_exec_query(sql, name = "SQL", binds = [], prepare: false, async: false, allow_retry: false) # :nodoc:
          log(sql, name, binds) do |notification_payload|
            if prepare || binds.any?
              # TODO: refacto
              stmt = @raw_connection.prepare(sql)
              formated_binds = []
              binds.each_with_index do |bind, i|
                if bind.respond_to?("value_for_database")
                  stmt.param_type(i, ODBC::SQL_INTEGER) if bind.value.is_a?(Integer)
                  formated_binds << type_cast(bind.value_for_database)
                elsif bind.is_a?(Integer)
                  stmt.param_type(i, ODBC::SQL_INTEGER)
                  formated_binds << bind.to_i
                else
                  formated_binds << bind.to_s
                end
              end
              stmt.execute(*formated_binds.map(&:to_s))
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

        private

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
