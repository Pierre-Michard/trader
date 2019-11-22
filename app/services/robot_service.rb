class RobotService
  MAX_TRADE_AMOUNT= 0.8

  def initialize
  end

  def paymium_btc_balance
    PaymiumService.instance.balance_btc + PaymiumService.instance.locked_btc
  end

  def paymium_eur_balance
    PaymiumService.instance.balance_eur + PaymiumService.instance.locked_eur
  end

  def counterpart_eur_balance
    @counterpart_eur_balance ||=Setting.counter_orders_service.balance_eur
  end

  def counterpart_btc_balance
    @counterpart_btc_balance ||= Setting.counter_orders_service.balance_btc
  end

  def sell_capacity
    [paymium_btc_balance, (counterpart_eur_balance/counterpart_ask_price)].min
  end

  def buy_capacity
    [paymium_eur_balance/counterpart_bids_price, (counterpart_btc_balance)].min
  end

  def buy_presure
    buy_capacity/(buy_capacity+sell_capacity)
  end

  # https://mycurvefit.com/
  def buy_marge
    0.001358491 + 0.03864151*Math.exp(-3.521975*buy_presure)
  end

  # https://mycurvefit.com/
  def sell_marge
    0.001358491 + 0.03864151*Math.exp(-3.521975*sell_presure)
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

  def counterpart_ask_price(volume: MAX_TRADE_AMOUNT)
    Setting.counter_orders_service.asks_price(volume)
  end

  def counterpart_bids_price(volume: MAX_TRADE_AMOUNT)
    Setting.counter_orders_service.bids_price(volume)
  end

  def target_sell_price
    next_ask = PaymiumService.instance.highest_stranger_ask(counterpart_ask_price * (1 + sell_marge))
    next_ask[:price].to_d - 0.05
  end

  def target_buy_price
    next_ask = PaymiumService.instance.highest_stranger_bid(counterpart_bids_price * (1 - buy_marge))
    next_ask[:price].to_d + 0.05
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
    keep_only_last_order(current_sell_orders)
    keep_only_last_order(current_buy_orders)
  end

  def min_trade_amount
    Setting.counter_orders_service.minimum_amount
  end

  def monitor_price(direction: :buy)
    @is_counterpart_open_order = Trade.placing_counter_order?
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
        sleep(0.05)
      end

      amount = send("#{direction}_amount")
      if amount > min_trade_amount && !@is_counterpart_open_order
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
        Trade.find_or_create_trade(trade)
      rescue Exception => e
        logger.error "could not create trade #{trade[:uuid]}: #{trade[:amount]} #{e.message}"
      end
    end
  end

end