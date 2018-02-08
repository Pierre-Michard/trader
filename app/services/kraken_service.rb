class KrakenService < ExchangeService

  include Retriable

  CACHE_EXPIRATION_DELAY=61.seconds
  CONFIG = YAML.load(File.read(Rails.root.join('config', 'secret', 'kraken.yml'))).with_indifferent_access

  attr_reader :client

  def initialize
    KrakenClient.configure do |config|
      config.api_key     = CONFIG[:token]
      config.api_secret  = CONFIG[:secret]
      config.base_uri    = 'https://api.kraken.com'
      config.limiter     = true
      config.tier        = 2
    end
    @client = KrakenClient.load
  end

  def current_price
    BigDecimal(client.public.ticker('XXBTZEUR')['XXBTZEUR']['c'][0])
  end

  def balance(force_fetch: false)
    balance = Rails.cache.fetch(:kraken_balance, expires_in: CACHE_EXPIRATION_DELAY, force: force_fetch) do
      client.private.balance
    end
    AdjustedBalance.new(balance, open_orders).balance
  end

  def open_orders(force_fetch: false)
    Rails.cache.fetch(:kraken_open_orders, expires_in: CACHE_EXPIRATION_DELAY, force: force_fetch) do
      with_retries do
        client.private.open_orders['open'].inject({})do |hash, (order_id, order)|
          hash[order_id] = format_order(order, order_id)
          hash
        end
      end
    end
  end

  def closed_orders
    with_retries do
      client.private.closed_orders['closed'].inject({})do |hash, (order_id, order)|
        hash[order_id] = format_order(order, order_id)
        hash
      end
    end
  end

  def recent_orders
    open_orders.merge(closed_orders)
  end

  def cache_open_order(order)
    cached_orders = Rails.cache.read(:kraken_open_orders)
    if cached_orders
      cached_orders.merge!(order[:id] => order)
      Rails.cache.write(:kraken_open_orders, cached_orders, expires_in: CACHE_EXPIRATION_DELAY)
    end
  end

  def update_cache
    Rails.logger.warn('Update kraken cache')
    balance(force_fetch: true)
    open_orders(force_fetch: true)
  end

  def open_orders?
    not open_orders.count.zero?
  end

  def balance_eur
    BigDecimal.new(balance[:ZEUR] || '0')
  end

  def balance_btc
    BigDecimal.new(balance[:XXBT] || '0')
  end

  def cancel_order(order)
    Rails.cache.delete(:kraken_balance)
    client.delete("user/orders/#{order['uuid']}/cancel")
  end

  def minimum_amount
    0.002
  end

  def place_order(type: :market, direction:, btc_amount:, price: nil)
    order = {
        pair: 'XXBTZEUR',
        type: direction.to_s,
        ordertype: type.to_s,
        volume: btc_amount
    }
    order.merge!(price: price) if type != :market

    res = with_retries(nb_retries: 0) do
      client.private.add_order(order)
    end

    cached_order = {
        id: res['txid'][0],
        side: direction.to_s,
        type: type.to_s,
        vol: btc_amount,
        status: :opened,
        created_at: DateTime.now,
        price: price
    }.with_indifferent_access

    cache_open_order(cached_order)

    cached_order[:id]
  end


  def order(order_uuid)
    res = client.private.query_orders(txid: order_uuid, trades: true)
    format_order(res[order_uuid], order_uuid)
  end


  def orders(order_uuids)
    orders = client.private.query_orders(txid: order_uuids.join(','))
    orders.inject({})do |hash, (order_id, order)|
      hash[order_id] = format_order(order, order_id)
      hash
    end
  end

  private

  def format_order(order, uuid)
    {
        id: uuid,
        vol: BigDecimal(order[:vol]),
        side: order[:descr][:type],
        type: order[:descr][:ordertype],
        status: format_status(order[:status]),
        cost: BigDecimal(order[:cost]),
        fee: BigDecimal(order[:fee]),
        price: BigDecimal(order[:price]),
        created_at: Time.at(order[:opentm])
    }.with_indifferent_access
  end

  def format_status(status)
    case status
      when 'closed'
        :closed
      when 'open', 'untouched', 'touched', 'active'
        :opened
      when 'canceled'
        :canceled
    end
  end


  class AdjustedBalance
    def initialize(kraken_balance, open_orders)
      @balance = kraken_balance.dup
      @open_orders = open_orders.dup
      adjust_balance
    end

    def balance
      @balance
    end

    def adjust_balance
      @open_orders.each do |_key, order|
        if order[:side] == 'buy'
          update_balance(:eur, buy_order_estimated_cost(type: order[:type].to_sym, price: order[:price], btc_amount: order[:vol]))
        else
          update_balance(:btc, -order[:volume])
        end
      end
    end

    def update_balance(currency, diff)
      key = translate_currency(currency)
      @balance[key] = (@balance[key].to_f + diff).to_s
    end

    def translate_currency(currency)
      case currency
        when :eur
          :ZEUR
        when :btc
          :XXBT
        else
          raise "unknown currency #{currency}"
      end
    end

    def buy_order_estimated_cost(type:, price:, btc_amount:)
      case type
        when :market
          - KrakenService.instance.asks_price(btc_amount) * btc_amount
        when :limit
          - price*btc_amount
        else
          raise "unknown order type #{type}"
      end
    end
  end


end