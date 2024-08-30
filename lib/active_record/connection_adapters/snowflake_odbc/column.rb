module ActiveRecord
  module ConnectionAdapters
    module SnowflakeOdbc
      class Column < ConnectionAdapters::Column # :nodoc:
        def initialize(...)
          super
        end
      end
    end
  end
end