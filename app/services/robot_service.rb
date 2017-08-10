class RobotService

  MARGE_TOLERANCE= 0.0005
  MIN_TRADE_AMOUNT= 0.001
  MAX_TRADE_AMOUNT= 0.8

  def initialize
    @marge_tolerance = MARGE_TOLERANCE
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
    0.001529412 + 0.02847059*Math.exp(-2.963209*buy_presure)
  end

  # https://mycurvefit.com/
  def sell_marge
    0.03 - 0.015*sell_presure - 0.01*sell_presure**2
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
    [ kraken_ask_price *  (1 + sell_marge),
      (PaymiumService.instance.highest_stranger_ask[:price] - 2)].max
  end

  def target_buy_price
    [ (kraken_bids_price *  (1 - buy_marge)),
      (PaymiumService.instance.highest_stranger_bid[:price] + 2)].min
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
    @is_kraken_open_order = (@is_kraken_open_order.nil?)? KrakenService.instance.open_orders? : @is_kraken_open_order
    logger.info "monitor_#{direction}_price"
    target_price = send("target_#{direction}_price")
    min_price = target_price * (1 - @marge_tolerance)
    max_price = target_price * (1 + @marge_tolerance)
    logger.info "target #{direction} price #{target_price.to_f} [#{min_price.to_f}-#{max_price.to_f}]"

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