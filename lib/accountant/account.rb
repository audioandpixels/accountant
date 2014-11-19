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

  def balance_at(date)
    Money.new(lines.where(["created_at <= ?", date]).sum(:amount_money))
  end

  def aggregate_lines_by_day(n_days)
    grouped_lines = lines.group_by_day(:created_at, range: n_days.days.ago..Time.now).group(:description)
    sums = grouped_lines.sum(:amount_money).to_a

    grouped_lines.count.each_with_index.map do |count, i|
      next if count[1].zero?
      Accountant::AggregateLine.new(count[0][0], count[0][1], sums[i][1], count[1], balance_at(count[0][0]))
    end.compact
  end

end

class Accountant::AggregateLine < Struct.new(:date, :description, :amount_money, :count, :balance)

  def amount
    Money.new(amount_money)
  end

end
