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
  end

  def deleteable?
    lines.empty?
  end

  def aggregate_lines_by_day(n_days)
    sums = lines.group_by_day(:created_at, range: n_days.ago..Time.now).sum(:amount_money)
    counts = lines.group_by_day(:created_at, range: n_days.ago..Time.now).count

    raise "Aggregate keys do not match" if sums.keys != counts.keys

    sums.keys.map do |date|
      Accountant::GroupedLines.new(date: date, amount_money:sums[date], count: counts[date])
    end
  end

end

class Accountant::GroupedLines < Struct.new(:date, :amount_money, :count)

  def amount
    amount_money.to_money
  end

end
