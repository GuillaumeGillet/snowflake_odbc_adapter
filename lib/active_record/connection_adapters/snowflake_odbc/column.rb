module ActiveRecord
  module ConnectionAdapters
    module SnowflakeOdbc
      class Column < ConnectionAdapters::Column # :nodoc:
        def initialize(name, default, sql_type_metadata = nil, null = true, default_function = nil, collation: nil,
                       comment: nil, **options)
          super(name, _default(default), sql_type_metadata, null, default_function,
          collation: collation,
          comment: comment, **options)
        end

        private

        def _default(default)
          return nil if default.empty?

          default
        end
      end
    end
  end
end
