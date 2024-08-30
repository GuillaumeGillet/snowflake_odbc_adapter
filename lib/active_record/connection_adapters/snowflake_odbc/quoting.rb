require "snowflake_odbc_adapter/metadata"

module ActiveRecord
  module ConnectionAdapters
    module SnowflakeOdbc
      module Quoting # :nodoc:
        extend ActiveSupport::Concern # :nodoc:
        module ClassMethods # :nodoc:
          # Returns a quoted form of the column name.
          def quote_column_name(name)
            name = name.to_s
            quote_char = identifier_quote_char.to_s.strip
            return name if quote_char.empty?

            quote_char = quote_char[0]
            # Avoid quoting any already quoted name
            return name if name[0] == quote_char && name[-1] == quote_char

            # If upcase identifiers, only quote mixed case names.
            return name if upcase_identifiers? && name !~ /([A-Z]+[a-z])|([a-z]+[A-Z])/

            "#{quote_char.chr}#{name}#{quote_char.chr}"
          end

          def quote_table_name(name)
            name
          end

          private

          def identifier_quote_char
            ::SnowflakeOdbcAdapter::Metadata.instance.identifier_quote_char
          end

          def upcase_identifiers?
            ::SnowflakeOdbcAdapter::Metadata.instance.upcase_identifiers?
          end
        end
      end
    end
  end
end
