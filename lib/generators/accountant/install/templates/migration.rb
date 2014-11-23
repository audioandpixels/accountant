class CreateAccountantTables < ActiveRecord::Migration

  def self.up
    create_table "accountant_accounts", force: true do |t|
      t.integer  "holder_id",                    null: false
      t.string   "holder_type",                  null: false
      t.string   "name",                         null: false
      t.integer  "balance_money", default: 0,    null: false
      t.integer  "line_count",    default: 0
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "accountant_accounts", ["holder_id", "holder_type", "name"], name: 'account_unique', unique: true

    create_table "accountant_lines", force: true do |t|
      t.integer  "account_id",                    null: false
      t.integer  "other_account_id",              null: false
      t.integer  "amount_money",     default: 0,  null: false
      t.integer  "balance_money",     default: 0,  null: false
      t.integer  "reference_id"
      t.string   "reference_type"
      t.string   "description"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
    add_index "accountant_lines", "account_id"
    add_index "accountant_lines", ["reference_type", "reference_id"], name: "reference"

    create_table "accountant_global_accounts", force: true do |t|
      t.string   "name", null: false
    end
  end

  def self.down
  end

end
