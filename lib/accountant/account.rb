class Accountant::Account < ActiveRecord::Base
  self.table_name = :accountant_accounts

  belongs_to :holder, polymorphic: true
  has_many :lines, class_name: 'Accountant::Line'

  monetize :balance_money, as: 'balance'

  class << self

    def for(name)
      Accountant::GlobalAccount.find_or_create_by(name: name).account
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

    def recalculate_balances
      Accountant::Account.update_all(balance_money: 0)
      
      sql = <<-SQL
        SELECT
          account_id AS id,
          sum(amount_money) AS calculated_balance
        FROM
          accountant_lines
        GROUP BY
          account_id
        HAVING
          count(*) > 0
        SQL

      Accountant::Account.find_by_sql(sql).each do |account|
        account.lock!
        account.update_attributes(balance_money: account.calculated_balance)

        puts "account:#{account.id}, balance:#{account.balance}"
      end
    end
  end

  def deleteable?
    lines.empty?
  end

  def aggregate_by_day(n_days)
    Accountant::AggregateLine.by_day(self.id, n_days)
  end

end