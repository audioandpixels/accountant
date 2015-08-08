require 'accountant/active_record/account_extensions'
require 'accountant/active_record/locking_extensions'

ActiveRecord::Base.class_eval do
  include Accountant::ActiveRecord::AccountExtensions
  include ActiveRecord::LockingExtensions
end

module Accountant
  class Railtie < ::Rails::Railtie
    initializer 'accountant.initialize' do
      require 'money-rails'
      MoneyRails::Hooks.init

      require 'accountant/version'
      require 'accountant/transfer'
      require 'accountant/account'
      require 'accountant/line'
      require 'accountant/aggregate_line'
      require 'accountant/global_account'
      require 'accountant/manually_created_account'
    end
  end

  class << self
    def transfer(amount, from_account, to_account, *args)
      Accountant::Transfer.new.transfer(amount, from_account, to_account, args)
    end

    def multi_transfer(*accounts, &block)
      Accountant::Transfer.new.multi_transfer(*accounts, &block)
    end
  end
end
