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

    def check_balances
      # TODO - recalculate and check all account balances
    end

  end

  def deleteable?
    lines.empty?
  end

  def aggregate_by_day(n_days)
    sql = <<-SQL
      SELECT   (date_trunc('day', (created_at::timestamptz - interval '0 hour') at time zone 'Etc/UTC') + interval '0 hour') at time zone 'Etc/UTC' AS day,
               description                                                                                                                          AS description,
               count(*)                                                                                                                             AS count_all,
               sum(accountant_lines.amount_money)                                                                                                   AS sum_amount_money
      FROM     accountant_lines 
      WHERE    accountant_lines.account_id = #{self.id} 
      AND      (created_at >= '#{n_days.days.ago.beginning_of_day}' AND created_at <= '#{Time.now.utc.end_of_day}') 
      GROUP BY (date_trunc('day', (created_at::timestamptz - interval '0 hour') at time zone 'Etc/UTC') + interval '0 hour') at time zone 'Etc/UTC',
               description
    SQL

    grouped_lines = ActiveRecord::Base.connection.execute(sql).values

    grouped_lines.map! do |group|
      Accountant::AggregateLine.new(group[0].to_date, group[1], group[2], group[3])
    end.sort! { |a, b| b.date <=> a.date }

    rolling_balance(balance, grouped_lines)
  end

  def rolling_balance(final_balance, grouped_lines)
    grouped_lines.each_with_index do |grouped_line, i|
      if i == 0 
        grouped_line.balance = final_balance
      else
        grouped_line.balance = grouped_lines[i - 1].balance - grouped_lines[i - 1].amount
      end
    end
  end

end

class Accountant::AggregateLine < Struct.new(:date, :description, :count, :amount_money, :balance)
  def amount
    Money.new(amount_money)
  end
end