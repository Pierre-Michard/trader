class ExchangeService
  include Singleton
  include WithPublicTrades
  include WithSdepth

  def current_price
    last_trade[:price]
  end

  def balance_eur
    raise NotImplementedError.new("#{__method__} is a virtual method")
  end

  def balance_btc
    raise NotImplementedError.new("#{__method__} is a virtual method")
  end

  def place_order(type: :market, direction:, btc_amount:, price: nil)
    raise NotImplementedError.new("#{__method__} is a virtual method")
  end

  def order(order_id)
    raise NotImplementedError.new("#{__method__} is a virtual method")
  end

  def open_orders
    raise NotImplementedError.new("#{__method__} is a virtual method")
  end

  def open_orders?
    raise NotImplementedError.new("#{__method__} is a virtual method")
  end

end
