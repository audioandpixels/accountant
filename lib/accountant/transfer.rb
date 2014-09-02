class Accountant::Transfer
  @@locks = {}

  def multi_transfer(*accounts)
    @@locks = Hash.new
    outermost_transaction!

    ActiveRecord::Base.restartable_transaction do
      self.locks = accounts.sort_by(&:id).map(&:lock!)
      yield
    end

    remove_locks
  end

  def transfer(amount, from_account, to_account, reference = nil)
    if locked_transaction?
      [from_account, to_account].each {|ac| locked!(ac)}
      perform(amount, from_account, to_account, reference)
    else
      outermost_transaction!

      ActiveRecord::Base.restartable_transaction do
        [from_account, to_account].sort_by(&:id).map(&:lock!)
        perform(amount, from_account, to_account, reference)
      end
    end
  end

  private

  def perform(amount, from_account, to_account, reference)
    if (amount < 0)
      # Change order if amount is negative
      amount, from_account, to_account = -amount, to_account, from_account
    end

    add_line(-amount,  from_account,   to_account, reference)
    add_line( amount,    to_account, from_account, reference)
  end

  def add_line(amount, account, other_account, reference)
    line = Accountant::Line.new(amount: amount,
                                account: account,
                                other_account: other_account,
                                reference: reference)

    account.class.update_counters(account.id, line_count: 1, balance_money: line.amount_money)

    balance_negative!(account)

    line.save(validate: false)
    account.save(validate: false)
  end

  def outermost_transaction!
    unless Accountant::Account.connection.open_transactions.zero?
      raise MustBeOutermostTransaction
    end
  end

  def balance_negative!(account)
    raise ConfigNotLoaded if account.config.nil?

    if !account.config[:negative] and account.reload.balance < Money.new(0)
      raise AccountCannotBeNegative
    end
  end

  def locks
    @@locks[Thread.current.object_id]
  end

  def locks=(locks)
    @@locks[Thread.current.object_id] = locks
  end

  def remove_locks
    @@locks.delete(Thread.current.object_id)
  end

  def locked!(account)
    raise AccountNotLocked if !locks.include?(account)
  end

  def locked_transaction?
    !locks.nil?
  end

  class ConfigNotLoaded < RuntimeError
  end

  class MustBeOutermostTransaction < RuntimeError
  end

  class AccountNotLocked < RuntimeError
  end

  class AccountCannotBeNegative < RuntimeError
  end
end
