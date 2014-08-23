module Accountant
  class Transfer
    attr_accessor :amount, :reference, :from, :to, :journal, :valuta

    def initialize(line_1, line_2)
      @amount, @reference = line_2.amount, line_2.reference
      @from, @to = line_1.account, line_2.account
      @journal = line_1.journal
      @valuta = line_1.valuta
    end

    def referencing_a?(klass)
      reference.kind_of?(klass)
    end

    def reverse(valuta = Time.now, reference = @reference, amount = @amount)
      @journal.transfer(amount,
                        @to,
                        @from,
                        reference,
                        valuta)
    end
  end
end
