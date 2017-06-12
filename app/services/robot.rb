class Robot

  TARGET_BUY_MARGE= 0.0050
  TARGET_SELL_MARGE= 0.010
  MARGE_TOLERANCE= 0.0005
  MIN_TRADE_AMOUNT= 0.001
  MAX_TRADE_AMOUNT= 0.5

  def initialize
    @target_buy_marge = TARGET_BUY_MARGE
    @target_sell_marge = TARGET_SELL_MARGE
    @marge_tolerance = MARGE_TOLERANCE
  end

  def paymium_btc_balance
    @paymium_btc_balance ||= PaymiumService.instance.balance_btc
  end

  def paymium_eur_balance
    @paymium_eur_balance ||= PaymiumService.instance.balance_eur
  end

  def kraken_eur_balance
    @kraken_eur_balance ||=Kraken.instance.balance_eur
  end

  def kraken_btc_balance
    @kraken_btc_balance ||= Kraken.instance.balance_btc
  end

  def sell_amount
    @sell_amount ||= [paymium_btc_balance, (kraken_eur_balance/target_sell_price), MAX_TRADE_AMOUNT].min * 0.9
  end

  def buy_amount
    @buy_amount ||= [paymium_eur_balance/target_buy_price, (kraken_btc_balance), MAX_TRADE_AMOUNT].min * 0.9
  end

  def target_sell_price
    asks_price = KrakenSdepthService.asks_price(MAX_TRADE_AMOUNT)
    asks_price *  (1 + @target_sell_marge)
  end

  def target_buy_price
    bids_price = KrakenSdepthService.bids_price(MAX_TRADE_AMOUNT)
    bids_price *  (1 - @target_buy_marge)
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

  def monitor_price(direction: :buy)
    logger.info "monitor_#{direction}_price"
    target_price = send("target_#{direction}_price")
    min_price = target_price * (1 - @marge_tolerance)
    max_price = target_price * (1 + @marge_tolerance)
    logger.info "target #{direction} price #{target_price} [#{min_price}-#{max_price}]"

    current_order = send("current_#{direction}_orders").last
    logger.info "current_order price: #{current_order.try(:[], 'price')}"
    unless current_order &&
        current_order['price'] > min_price &&
        current_order['price'] < max_price

      if current_order
        logger.info "cancel #{direction} order"
        PaymiumService.instance.cancel_order(current_order)
      end

      amount = send("#{direction}_amount")
      if amount > MIN_TRADE_AMOUNT
        logger.info "place Paymium buy order amount: #{amount}, price #{target_price}"
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
      logger.info "trade #{trade[:uuid]}: #{trade[:amount]}"
      Trade.find_or_create_by!(paymium_uuid: trade[:uuid]) do |t|
        t.btc_amount= trade[:amount]
      end
    end

  end

end