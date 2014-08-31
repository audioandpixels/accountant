class Accountant::Transfer

  def lock_accounts(*accounts)
    outermost_transaction!

    restartable_transaction do
      [accounts].sort_by(&:id).map(&:lock!)
      yield
    end

    # Does this need to be ensured?
    clear_current
  end

  def transfer(amount, from_account, to_account, reference = nil)
    outermost_transaction!

    restartable_transaction do
      [from_account, to_account].sort_by(&:id).map(&:lock!)
      perform(amount, from_account, to_account, reference)
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

    line.save(validate: false)
    account.save(validate: false)
  end

  def outermost_transaction!
    unless Accountant::Account.connection.open_transactions.zero?
      raise MustBeOutermostTransaction
    end
  end

  class MustBeOutermostTransaction < RuntimeError
  end
end
