module Accountant
  class Account < ActiveRecord::Base
    self.table_name = :accountant_accounts

    belongs_to :holder, polymorphic: true
    has_many :lines, class_name: 'Accountant::Line'
    has_many :journals, through: :lines

    monetize :balance_money, as: "balance"

    class << self

      def recalculate_all_balances
        Accountant::Account.update_all(balance: 0, line_count: 0, last_valuta: nil)
        sql = <<-SQL
        SELECT
        account_id as id,
          count(*) as calculated_line_count,
          sum(amount) as calculated_balance,
          max(valuta) as calculated_valuta
        FROM
        accountant_lines
        GROUP BY
        account_id
        HAVING
        calculated_line_count > 0
        SQL

        Accountant::Account.find_by_sql(sql).each do |account|
          account.lock!
          account.update_attributes(balance: account.calculated_balance,
                                    line_count: account.calculated_line_count,
                                    last_valuta: account.calculated_valuta)
        end
      end

      def for(name)
        GlobalAccount.find_or_create_by(name: name).account
      end

      def create!(attributes = nil)
        find_on_error(attributes) do
          super
        end
      end

      def create(attributes = nil)
        find_on_error(attributes) do
          super
        end
      end

      def delete_account(number)
        transaction do
          account = find(number)
          raise ActiveRecord::ActiveRecordError, "Cannot be deleted" unless account.deleteable?

          account.holder.destroy if [ ManuallyCreatedAccount, GlobalAccount ].include?(account.holder.class)
          account.destroy
        end
      end

      def find_on_error(attributes)
        yield

        # Trying to create a duplicate key on a unique index raises StatementInvalid
      rescue ActiveRecord::StatementInvalid => e
        record = if attributes[:holder]
          attributes[:holder].account(attributes[:name])
        else
          where(holder_type: attributes[:holder_type],
                holder_id: attributes[:holder_id],
                name: attributes[:name]).first
        end
        record || raise("Cannot find or create account with attributes #{attributes.inspect}")
      end
    end

    def deleteable?
      lines.empty? && journals.empty?
    end
  end
end
