module Accountant
  class GlobalAccount < ActiveRecord::Base
    self.table_name = :accountant_global_accounts

    has_account
  end
end