module Accountant
  module ActiveRecord
    module AccountExtensions
      def self.included(base)
        base.extend ClassMethods
        base.class_eval do
          def account(name=:default, negative=true )
            __send__("#{name}_account") || __send__("create_#{name}_account", name: name.to_s, negative: negative)
          end
        end
      end

      module ClassMethods

        def has_account(name=:default)
          has_one :"#{name}_account", -> { where name: name }, class_name: "Accountant::Account", as: :holder

          unless instance_methods.include?('accounts')
            has_many :accounts, class_name: "Accountant::Account", as: :holder
          end
        end

        def is_reference
          has_many :lines, class_name: "Accountant::Line", as: :reference
          class_eval do
            def booked?
              lines.any?
            end
          end
        end

        def has_global_account(name)
          class_eval do
            def account
              Accountant::Account.for(name.to_sym)
            end
          end
        end
      end
    end
  end
end
