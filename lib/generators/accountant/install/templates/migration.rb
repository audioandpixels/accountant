class CreateAccountantTables < ActiveRecord::Migration

  def self.up
    create_table "accountant_accounts", :force => true do |t|
      t.integer  "holder_id", :null => false
      t.string   "holder_type", :null => false
      t.string   "name", :null => false

      t.integer  "balance", :default => 0
      t.integer  "postings_count", :default => 0
      t.datetime "last_valuta"

      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "accountant_accounts", ["holder_id", "holder_type", "name"], :name => 'account_unique', :unique => true

    create_table "accountant_journals", :force => true do |t|
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "accountant_lines", :force => true do |t|
      t.integer "account_id", :null => false
      t.integer "other_account_id", :null => false
      t.integer "journal_id", :null => false
      t.integer "amount", :null => false

      t.integer "reference_id"
      t.string "reference_type"

      t.datetime "valuta"

      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
    add_index "accountant_lines", "account_id"
    add_index "accountant_lines", "journal_id"
    add_index "accountant_lines", ["reference_type", "reference_id"], :name => "reference"
    add_index "accountant_lines", ["valuta", "id"], :name => "sort_key"

    create_table "accountant_global_accounts", :force => true do |t|
      t.string   "name", :null => false
    end

    create_table "users", :force => true do |t|
      t.string   "name", :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "abstract_users", :force => true do |t|
      t.string   "name", :null => false
      t.string   "type", :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "cheques", :force => true do |t|
      t.string "number"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end

  def self.down
  end

end
