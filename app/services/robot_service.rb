class RobotService
  MIN_TRADE_AMOUNT= 0.001
  MAX_TRADE_AMOUNT= 0.8

  def initialize
  end

  def paymium_btc_balance
    PaymiumService.instance.balance_btc + PaymiumService.instance.locked_btc
  end

  def paymium_eur_balance
    PaymiumService.instance.balance_eur + PaymiumService.instance.locked_eur
  end

  def kraken_eur_balance
    @kraken_eur_balance ||=KrakenService.instance.balance_eur
  end

  def kraken_btc_balance
    @kraken_btc_balance ||= KrakenService.instance.balance_btc
  end

  def total_paymium_virtual_btc
    paymium_btc_balance  + (paymium_eur_balance)/kraken_ask_price
  end

  def total_paymium_virtual_eur
    paymium_eur_balance  + (paymium_btc_balance)*kraken_ask_price
  end

  def total_kraken_virtual_btc
    kraken_btc_balance  + (kraken_eur_balance)/kraken_ask_price
  end

  def total_kraken_virtual_eur
    kraken_eur_balance  + (kraken_btc_balance)*kraken_ask_price
  end

  def total_virtual_btc
    total_kraken_virtual_btc + total_paymium_virtual_btc
  end

  def total_virtual_eur
    total_kraken_virtual_eur + total_paymium_virtual_eur
  end

  def total_btc
    kraken_btc_balance + paymium_btc_balance
  end

  def total_eur
    kraken_eur_balance + paymium_eur_balance
  end


  def sell_capacity
    [paymium_btc_balance, (kraken_eur_balance/kraken_ask_price)].min
  end

  def buy_capacity
    [paymium_eur_balance/kraken_bids_price, (kraken_btc_balance)].min
  end

  def buy_presure
    buy_capacity/(buy_capacity+sell_capacity)
  end

  # https://mycurvefit.com/
  def buy_marge
    0.003111111 + 0.02688889*Math.exp(-3.409496*buy_presure)
  end

  # https://mycurvefit.com/
  def sell_marge
    0.003111111 + 0.02688889*Math.exp(-3.409496*sell_presure)
  end

  def sell_presure
    sell_capacity/(buy_capacity+sell_capacity)
  end

  def sell_amount
    @sell_amount ||= [sell_capacity, MAX_TRADE_AMOUNT].min * 0.9
  end

  def buy_amount
    @buy_amount ||= [buy_capacity, MAX_TRADE_AMOUNT].min * 0.9
  end

  def kraken_ask_price(volume: MAX_TRADE_AMOUNT)
    KrakenSdepthService.asks_price(volume)
  end

  def kraken_bids_price(volume: MAX_TRADE_AMOUNT)
    KrakenSdepthService.bids_price(volume)
  end

  def target_sell_price
    next_ask = PaymiumService.instance.highest_stranger_ask(kraken_ask_price * (1 + sell_marge))
    next_ask[:price] - 0.05
  end

  def target_buy_price
    next_ask = PaymiumService.instance.highest_stranger_bid(kraken_bids_price * (1 - buy_marge))
    next_ask[:price] + 0.05
  end


  def keep_only_last_order(orders)
    if orders.size > 1
      orders[1..-1].each do |order|
        PaymiumService.instance.cancel_order(order)
      end
    end
  end

  def current_sell_orders
    @current_sell_orders ||= PaymiumService.instance.current_sell_orders
  end

  def current_buy_orders
    @current_buy_orders ||= PaymiumService.instance.current_buy_orders
  end

  def cleanup_orders
    #todo fix the bug and remove this
    #PaymiumService.instance.current_orders(force_fetch:true)
    keep_only_last_order(current_sell_orders)
    keep_only_last_order(current_buy_orders)
  end

  def monitor_price(direction: :buy)
    @is_kraken_open_order = (@is_kraken_open_order.nil?)? KrakenService.instance.open_orders? : @is_kraken_open_order
    logger.info "monitor_#{direction}_price"
    target_price = send("target_#{direction}_price")
    logger.info "target #{direction} price #{target_price.to_f}"

    current_order = send("current_#{direction}_orders").last
    logger.info "current_order price: #{current_order.try(:[], 'price')}"
    unless current_order &&
        current_order['price'] == target_price

      if current_order
        logger.info "cancel #{direction} order"
        PaymiumService.instance.cancel_order(current_order)
      end

      amount = send("#{direction}_amount")
      if amount > MIN_TRADE_AMOUNT && !@is_kraken_open_order
        logger.info "place Paymium #{direction} order amount: #{amount}, price #{target_price}"
        PaymiumService.instance.place_limit_order(direction: direction, btc_amount: amount, price: target_price)
      end
    end
  end

  def logger
    Rails.logger
  end

  def monitor_trades
    logger.info 'monitor trades'
    trades = PaymiumService.instance.latest_trades
    trades.each do |trade|
      begin
        logger.info "trade #{trade[:uuid]}: #{trade[:amount]}"
        Trade.find_or_create_by!(paymium_uuid: trade[:uuid]) do |t|
          t.btc_amount= trade[:amount]
          t.paymium_cost = trade[:counterpart][:amount]
          t.paymium_price = trade[:order][:price]
          t.paymium_order_uuid = trade[:order][:uuid]
        end
      rescue Exception => e
        logger.error "could not create trade #{trade[:uuid]}: #{trade[:amount]} #{e.message}"
      end
    end

  end

end