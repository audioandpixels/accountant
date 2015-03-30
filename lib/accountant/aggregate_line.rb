class Accountant::AggregateLine < Struct.new(:date, :description, :count, :amount_money, :balance_money)

  def self.by_day(account_id, n_days)
    sql = <<-SQL
      SELECT   (date_trunc('day', (created_at::timestamptz - interval '0 hour') at time zone 'Etc/UTC') + interval '0 hour') at time zone 'Etc/UTC' AS day,
               description                                                                                                                          AS description,
               count(*)                                                                                                                             AS count_all,
               sum(accountant_lines.amount_money)                                                                                                   AS sum_amount_money,
               (SELECT balance_money FROM accountant_accounts WHERE accountant_accounts.id = '#{account_id}' LIMIT 1)                               AS balance_money
      FROM     accountant_lines
      WHERE    accountant_lines.account_id = '#{account_id}'
      AND      (created_at >= '#{n_days.days.ago.beginning_of_day}' AND created_at <= '#{Time.now.end_of_day}')
      GROUP BY day, description
      ORDER BY day DESC
    SQL

    groups = ActiveRecord::Base.connection.execute(sql)

    groups.each_with_index.map do |group, i|
      @prev = Accountant::AggregateLine.new(group['day'].to_date, 
                                            group['description'],
                                            group['count_all'].to_i,
                                            group['sum_amount_money'].to_i,
                                            i.zero? ? group['balance_money'].to_i : @prev.balance_money - @prev.amount_money)
    end
  end

  def amount
    Money.new(amount_money)
  end

  def balance
    Money.new(balance_money)
  end
  
end