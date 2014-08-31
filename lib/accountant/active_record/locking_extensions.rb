module ActiveRecord
  module LockingExtensions
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def restartable_transaction(&block)
        begin
          transaction(&block)
        rescue ActiveRecord::StatementInvalid => exception
          if exception.message =~ /deadlock/i || exception.message =~ /database is locked/i
            # Sleep then retry? Limit number of times?
            retry
          else
            raise
          end
        end
      end
    end
  end
end
