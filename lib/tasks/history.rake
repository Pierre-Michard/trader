namespace :history do
  desc "TODO"
  task get: :environment do
    history = JSON.parse(File.read("tmp/orders.json"))
    initial_size = history.count
    offset = 0
    while(1)
      orders = PaymiumService.instance.get('user/orders', {'types[]': ['LimitOrder', 'MarketOrder'], offset: offset, limit: 20})
      offset += 15
      orders.each do |order|
        history[order[:uuid]] = order
        puts order[:uuid]
      end
      puts "last: #{orders.last[:created_at]}, size: #{history.keys.size}"
      break if orders.count < 20
    end

    puts "diff: #{history.count - initial_size}"

    f = File.open("tmp/orders.json", "w")
    f.write(JSON.pretty_generate(history))
  end

  task trades: :environment do
    history = JSON.parse(File.read("tmp/orders.json"))
    puts history.count
    trades = extract_trades(from_orders: history.values)
    f = File.open("tmp/trades.json", "w")
    puts "size: #{trades.size}"
    f.write(JSON.pretty_generate(trades))

    CSV.open("tmp/trades.csv", "wb") do |csv|
      csv << trades.first.keys # adds the attributes name on the first line
      trades.each do |hash|
        csv << hash.values
      end
    end
  end

  task rewards: :environment do
    history = JSON.parse(File.read("tmp/orders.json"))
    puts history.count
    rewards = extract_rewards(from_orders: history.values)
    f = File.open("tmp/rewards.json", "w")
    puts "size: #{rewards.size}"
    f.write(JSON.pretty_generate(rewards))

    CSV.open("tmp/rewards.csv", "wb") do |csv|
      csv << rewards.first.keys # adds the attributes name on the first line
      rewards.each do |hash|
        csv << hash.values
      end
    end
  end

  task transfers: :environment do
    history = {}
    offset = 0
    while(1)
      orders = PaymiumService.instance.get('user/orders', {'types[]': ['WireDeposit', 'BitcoinDeposit', 'Transfer'], offset: offset, limit: 20})
      offset += 20
      orders.each do |order|
        next if order[:state] == "canceled"
        history[order[:uuid]] = order
        puts order[:uuid]
      end
      puts "last: #{orders.last[:created_at]}, size: #{history.keys.size}"
      break if orders.count < 20
    end

    f = File.open("tmp/transfers.json", "w")
    f.write(JSON.pretty_generate(history))
  end

  task transfer_csv: :environment do
    transfers = []
    #Koinly Date	Amount	Currency	Label	TxHash
    history = JSON.parse(File.read("tmp/transfers.json"))
    history.values.map do |order|
      if order["type"] == "Transfer"
        amount = (-order["amount"].to_d).to_s
      else
        amount = order["amount"]
      end

      transfers << {
        "Koinly Date" => order["created_at"],
        "amount" => amount,
        "Currency" => order["currency"],
        "Label" => order["comment"],
        "TxHash" => order["txid"],
        "Description" => "#{order['type']}##{order['uuid']} #{order["bitcoin_address"]}"
      }
    end

    CSV.open("tmp/transfers.csv", "wb") do |csv|
      csv << transfers.first.keys # adds the attributes name on the first line
      transfers.each do |hash|
        csv << hash.values
      end
    end
  end

  task balance_reco: :environment do
    balance_history = []
    currency = "BTC"
    transfers = CSV.open("tmp/transfers.csv", headers: :first_row).map(&:to_h)
    trades = CSV.open("tmp/trades.csv", headers: :first_row).map(&:to_h)

    transfers.each do |transfer|
      if transfer["Currency"] == currency
        balance_history << {
          "amount" => transfer["amount"].to_d,
          "Koinly Date" => Time.zone.parse(transfer["Koinly Date"]),
          "Description" => transfer["Description"]
        }
      end
    end

    trades.each do |trade|
      #Koinly Date,Pair,Side,Amount,Total,Fee Amount,Fee Currency,Order ID,Trade ID
      if trade["Side"] == "Sell"
        amount = - trade["Amount"].to_d
      elsif trade["Side"] == "Buy"
        amount = trade["Amount"].to_d
      else
        raise "unknown side #{trade["Side"]}"
      end

      if trade["Fee Currency"] == "BTC"
        amount -= trade["Fee Amount"].to_d
      end

      balance_history << {
        "amount" => amount,
        "Koinly Date" => Time.zone.parse(trade["Koinly Date"]),
        "Description" => "order #{trade["Order ID"]}"
      }
    end

    balance_history.sort_by!{|row| row["Koinly Date"]}


    CSV.open("tmp/balance.csv", "wb") do |csv|
      csv << balance_history.first.keys # adds the attributes name on the first line
      balance_history.each do |hash|
        csv << hash.values
      end
    end
  end

  def extract_trades(from_orders:)
    from_orders.
      map{|o| o['account_operations'].map{|ao| ao.merge({'order' => o})}}.
      flatten.
      each_cons(3).
      select{|prev, ao, fee| ['btc_purchase','btc_sale'].include?(ao['name']) && ao['currency'] == 'BTC'}.
      map do |prev, ao, fee|
      raise "counterparty does not match" unless ['btc_purchase','btc_sale'].include?(prev['name'])
      raise "counterparty does not match" unless ['EUR'].include?(prev['currency'])

      if ['btc_purchase_fee','btc_sale_fee'].include?(fee['name'])
        fee_amount = fee['amount'].to_d.abs.to_s
      else
        fee_amount = "0"
      end
      {
        "Koinly Date" => Time.parse(ao['created_at']),
        "Pair" => "BTC-EUR",
        "Side" => ao['name'] == 'btc_purchase'? "Buy" : "Sell",
        "Amount" => ao['amount'].to_d.abs.to_s,
        "Total" => prev['amount'].to_d.abs.to_s,
        "Fee Amount" => fee_amount,
        "Fee Currency" => fee["currency"],
        "Order ID" => ao['order']['uuid'],
        "Trade ID" => ao['uuid']
      }
    end
  end

  def extract_rewards(from_orders:)
    from_orders.
      map{|o| o['account_operations'].map{|ao| ao.merge({'order' => o})}}.
      flatten.
      select{|ao| %w[btc_purchase_fee_incentive btc_sale_fee_incentive].include?(ao['name'])}.
      map do |ao|
        {
          "Amount" => ao['amount'],
          "Currency" => ao['currency'],
          "Koinly Date" => Time.zone.parse(ao["created_at"]),
          "Description" => "order #{ao['order']["uuid"]}",
          "Label" => "Reward"
        }
    end
  end
end
