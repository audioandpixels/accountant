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

  # TODO: Rework into SQL?
  def aggregate_lines_by_day(n_days)
    range = n_days.days.ago..Time.now
    descriptions = lines.where(created_at: range).pluck('DISTINCT description')
    
    group_aggregate_data(range, descriptions)
  end

  private

  def group_aggregate_data(range, descriptions)
    data = {}

    descriptions.each do |desc|
      data[desc] = { 'sums' => lines.where(description: desc).group_by_day(:created_at, range: range).sum(:amount_money),
                     'counts' => lines.where(description: desc).group_by_day(:created_at, range: range).count }
    end

    group_lines(data)
  end

  def group_lines(data)
    grouped_lines = []
    data.values[0]['sums'].keys.each do |date|
      data.keys.each do |desc|
        next if data[desc]['counts'][date].zero?
        grouped_lines << Accountant::GroupedLines.new(date, desc, data[desc]['sums'][date], data[desc]['counts'][date])
      end
    end

    grouped_lines
  end

end

class Accountant::GroupedLines < Struct.new(:date, :description, :amount_money, :count)

  def amount
    Money.new(amount_money)
  end

end
