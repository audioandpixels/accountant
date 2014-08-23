module Accountant
  module ActiveRecordExtension
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        def account(name = :default)
          __send__("#{name}_account") || __send__("create_#{name}_account", :name => name.to_s)
        end
      end
    end

    module ClassMethods

      def has_account(name = :default)
        has_one :"#{name}_account", -> { where name: name }, class_name: "Accountant::Account", as: :holder

        unless instance_methods.include?('accounts')
          has_many :accounts, class_name: "Accountant::Account", as: :holder
        end
      end

      def is_reference
        has_many :postings, class_name: "Accountant::Posting", as: :reference
        class_eval <<-EOS
          def booked?
            lines.any?
          end
        EOS
      end

      def has_global_account(name)
        class_eval <<-EOS
          def account
            Accountant::Account.for(:#{name})
          end
        EOS
      end
    end
  end
end
