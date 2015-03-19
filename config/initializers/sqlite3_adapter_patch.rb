module ActiveRecord
  module ConnectionAdapters
    class SQLite3Adapter < AbstractAdapter
      QUOTED_TRUE, QUOTED_FALSE = "'t'", "'f'"

      def quoted_true
        QUOTED_TRUE
      end

      def quoted_false
        QUOTED_FALSE
      end
    end
  end
end