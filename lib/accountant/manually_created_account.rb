class Accountant::ManuallyCreatedAccount < ActiveRecord::Base
  self.table_name = :accountant_manually_created_accounts

  has_account

  validates_length_of :name, minimum: 1
end
