require 'active_record'
require 'action_controller'
require 'money-rails'
# require 'money-rails/hooks'
# MoneyRails::Hooks.init

require 'accountant/version'
require 'accountant/transfer'
require 'accountant/account'
require 'accountant/journal'
require 'accountant/line'
require 'accountant/active_record/extensions'

# ActiveRecord::Base.class_eval do
#   include Accountant::ActiveRecordExtension
# end

require 'accountant/global_account'
require 'accountant/manually_created_account'