class GdaxService < ExchangeService
  CACHE_EXPIRATION_DELAY=2.seconds
  CONFIG = YAML.load(File.read(Rails.root.join('config', 'secret', 'gdax.yml'))).with_indifferent_access

  attr_reader :client

  def initialize
    @client = Coinbase::Exchange::Client.new(
        CONFIG[:token],
        CONFIG[:secret],
        CONFIG[:passphrase])
  end

  def balance(force_fetch: false)
    Rails.cache.fetch(:gdax_balance, expires_in: CACHE_EXPIRATION_DELAY, force: force_fetch) do
      client.accounts.reduce({}.with_indifferent_access) do |h, account|
        h.merge({
            account.currency.downcase => {
                available: account.available,
                locked: account.hold
            }
        })
      end
    end
  end

  def balance_eur
    balance[:eur][:available]
  end

  def balance_btc
    balance[:btc][:available]
  end

  def minimum_amount
    0.001
  end

  def place_order(type: :market, direction:, btc_amount:, price: nil)
    Rails.cache.delete(:gdax_balance)
    case direction
      when :buy
        res = client.buy(btc_amount, price, product_id: 'BTC-EUR', type: type)
      when :sell
        res = client.sell(btc_amount, price, product_id: 'BTC-EUR', type: type)
      else
        raise 'Unknown direction'
    end
    res['id']
  end

  def order(order_id)
    res = client.order(order_id)
    format_order(res)
  end

  def open_orders
    orders(status: 'open')
  end

  def open_orders?
    open_orders.size > 0
  end

  def recent_orders
    orders(status: 'all')
  end

  def orders(status:)
    orders = client.orders(status: status)
    orders.reduce({}) do |h, order|
      h[order.id] = format_order(order)
      h
    end
  end

  def orderbook
    res = client.orderbook(product_id: 'BTC-EUR', level: 2)
    %w(bids asks).reduce({}) do |stack, key|
      stack[key.to_sym] = res[key].map do |price, amount, _nb_trades|
        {
            price: BigDecimal(price),
            amount: BigDecimal(amount)
        }
      end
      stack
    end
  end

  def get_last_trade
    res = client.last_trade(product_id: 'BTC-EUR')
    {price: res['price'], volume: res['volume'], time: Time.parse(res['time'])}
  end

  private

  def format_status(status)
    case status
      when 'done', 'settled'
        :closed
      when 'open', 'pending', 'active'
        :active
    end
  end

  def format_order(order)
    {
        id: order.id,
        vol: order.size,
        side: order.side,
        type: order.type,
        status: format_status(order.status),
        cost: order.executed_value,
        fee: order.fill_fees,
        price: (order.filled_size == 0)? nil : (order.executed_value / order.filled_size),
        created_at: Time.parse(order['created_at'])
    }.with_indifferent_access
  end

end