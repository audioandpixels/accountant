require 'active_record'
require 'action_controller'

require 'accountant/version'
require 'accountant/transfer'
require 'accountant/account'
require 'accountant/journal'
require 'accountant/line'
require 'accountant/active_record/extensions'
require 'accountant/global_account'
require 'accountant/manually_created_account'

ActiveRecord::Base.class_eval do
  include ActsAsAccount::ActiveRecordExtension
end