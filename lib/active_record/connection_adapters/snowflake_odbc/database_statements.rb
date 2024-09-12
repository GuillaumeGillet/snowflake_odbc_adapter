module ActiveRecord
  module ConnectionAdapters # :nodoc:
    module SnowflakeOdbc
      module DatabaseStatements
        # Have to because of create table
        def prepared_statements
          true
        end

        # Executes the SQL statement in the context of this connection.
        # Returns the number of rows affected.
        def execute(sql, name = nil, binds = [])
          log(sql, name, binds) do |notification_payload|
            rc = @raw_connection.do(sql, *binds.map { |bind| prepare_bind(bind).to_s })
            notification_payload[:row_count] = rc
            rc
          end
        end

        # Executes delete +sql+ statement in the context of this connection using
        # +binds+ as the bind substitutes. +name+ is logged along with
        # the executed +sql+ statement.
        def exec_delete(sql, name, binds)
          execute(sql, name, binds)
        end

        # Begins the transaction (and turns off auto-committing).
        def begin_db_transaction
          @raw_connection.autocommit = false
        end

        # Commits the transaction (and turns on auto-committing).
        def commit_db_transaction
          @raw_connection.commit
          @raw_connection.autocommit = true
        end

        # Rolls back the transaction (and turns on auto-committing). Must be
        # done if the transaction block raises an exception or returns false.
        def exec_rollback_db_transaction
          @raw_connection.rollback
          @raw_connection.autocommit = true
        end

        def internal_exec_query(sql, name = "SQL", binds = [], prepare: false, async: false, allow_retry: false) # :nodoc:
          log(sql, name, binds) do |notification_payload|
            if prepare || binds.any?
              # TODO: refacto
              stmt = @raw_connection.prepare(sql)
              binds.each_with_index do |bind, i|
                if bind.respond_to?("value_for_database") && bind.value.is_a?(Integer) || bind.is_a?(Integer)
                  stmt.param_type(i, ODBC::SQL_INTEGER)
                end
              end
              stmt.execute(*binds.map { |bind| prepare_bind(bind).to_s })
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

        def prepare_bind(bind)
          if bind.respond_to?("value_for_database")
            type_cast(bind.value_for_database)
          elsif bind.is_a?(Integer)
            bind.to_i
          else
            bind.to_s
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
