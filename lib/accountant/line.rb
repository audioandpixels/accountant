class Accountant::Line < ActiveRecord::Base
  self.table_name = :accountant_lines

  belongs_to :account,       class_name: 'Accountant::Account'
  belongs_to :other_account, class_name: 'Accountant::Account'
  belongs_to :journal,       class_name: 'Accountant::Journal'
  belongs_to :reference, polymorphic: true

  monetize :amount_money, as: 'amount'
end
