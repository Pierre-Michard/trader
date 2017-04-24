class Robot

  TARGET_BUY_MARGE= 0.0050
  TARGET_SELL_MARGE= 0.0050
  MARGE_TOLERANCE= 0.0001
  MIN_TRADE_AMOUNT= 0.001
  MAX_TRADE_AMOUNT= 0.1

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
    @target_sell_price ||= asks_price *  (1 + @target_sell_marge)
  end

  def target_buy_price
    bids_price = KrakenSdepthService.bids_price(MAX_TRADE_AMOUNT)
    @target_buy_price ||= bids_price *  (1 - @target_buy_marge)
  end

  def current_price
    @current_price ||= Kraken.instance.current_price
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

  def monitor_sell_price
    @target_sell_price = target_sell_price
    min_sell_price = @target_sell_price * (1 - @marge_tolerance)
    max_sell_price = @target_sell_price * (1 + @marge_tolerance)

    p "target sell price #{@target_sell_price} [#{min_sell_price}-#{max_sell_price}]"
    current_sell_order = current_sell_orders.last
    unless current_sell_order &&
        current_sell_order['price'] > min_sell_price &&
        current_sell_order['price'] < max_sell_price
      if current_sell_order
        p "cancel sell order"
        PaymiumService.instance.cancel_order(current_sell_order)
      end
      @sell_amount = sell_amount
      if @sell_amount > MIN_TRADE_AMOUNT
        p "place paymium sell order amount: #{@sell_amount}, price #{@target_sell_price}"
        PaymiumService.instance.place_limit_order(direction: :sell, btc_amount: @sell_amount, price: @target_sell_price)
      end
    end
  end

  def monitor_buy_price
    p 'monitor_buy_price'
    @target_buy_price = target_buy_price
    min_buy_price = @target_buy_price * (1 - @marge_tolerance)
    max_buy_price = @target_buy_price * (1 + @marge_tolerance)

    p "target buy price #{@target_buy_price} [#{min_buy_price}-#{max_buy_price}]"
    current_buy_order = current_buy_orders.last
    unless current_buy_order &&
        current_buy_order['price'] > min_buy_price &&
        current_buy_order['price'] < max_buy_price
      p 'cancel buy order'
      PaymiumService.instance.cancel_order(current_buy_order) if current_buy_order
      @buy_amount = buy_amount
      if @buy_amount > MIN_TRADE_AMOUNT
        p "place paymium buy order amount: #{@buy_amount}, price #{@target_buy_price}"
        PaymiumService.instance.place_limit_order(direction: :buy, btc_amount: @buy_amount, price: @target_buy_price)
      end
    end
  end

  def monitor_trades
    p 'monitor trades'
    trades = PaymiumService.instance.latest_trades
    trades.each do |trade|
      p "trade #{trade[:uuid]}: #{trade[:amount]}"
      Trade.find_or_create_by!(paymium_uuid: trade[:uuid]) do |t|
        t.btc_amount= trade[:amount]
      end
    end

  end

end