module Accountant
  class Journal < ActiveRecord::Base
    self.table_name = :accountant_journals

    has_many :postings, class_name: 'Accountant::Posting'
    has_many :accounts, through: :lines

    class << self
      private :new
      private :create
      private :create!

      def current
        Thread.current[:accountant_current] ||= create!
      end

      def clear_current
        Thread.current[:accountant_current] = nil
      end
    end

    def transfers
      [].tap do |transfers|
        lines.in_groups_of(2) { |lines| transfers << Transfer.new(*lines) }
      end
    end

    def transfer(amount, from_account, to_account, reference = nil, valuta = Time.now)
      transaction do
        if (amount < 0)
          # change order if amount is negative
          amount, from_account, to_account = -amount, to_account, from_account
        end

        # to avoid possible deadlocks we need to ensure that the locking order is always
        # the same therfore the sort by id.
        [from_account, to_account].sort_by(&:id).map(&:lock!)

        add_posting(-amount,  from_account,   to_account, reference, valuta)
        add_posting( amount,    to_account, from_account, reference, valuta)
      end
    end

    private

    def add_posting(amount, account, other_account, reference, valuta)
      posting = postings.build(amount: amount,
                               account: account,
                               other_account: other_account,
                               reference: reference,
                               valuta: valuta)

      account.class.update_counters(account.id, line_count: 1, balance: line.amount)

      posting.save(validate: false)
      account.save(validate: false)
    end
  end
end
