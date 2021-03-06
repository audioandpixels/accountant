require 'rails/generators'
require 'rails/generators/migration'
require 'rails/generators/active_record'

# Generate money-rails config
# Generate accountant config

module Accountant::Generators
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path('../templates', __FILE__)

    def self.next_migration_number(path)
      ActiveRecord::Generators::Base.next_migration_number(path)
    end

    def copy_migrations
      migration_template "migration.rb", "db/migrate/create_accountant_tables.rb"
    end

  end
end
