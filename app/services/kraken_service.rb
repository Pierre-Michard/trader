require 'singleton'

class KrakenService
  include Singleton
  include WithPublicTrades
  include WithSdepth

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
    client.public.ticker('XXBTZEUR')['XXBTZEUR'].c[0].to_f
  end

  def balance(force_fetch: false)
    balance = Rails.cache.fetch(:kraken_balance, expires_in: CACHE_EXPIRATION_DELAY.seconds, force: force_fetch) do
      client.private.balance
    end
    AdjustedBalance.new(balance, open_orders).balance
  end

  def open_orders(force_fetch: false)
    Rails.cache.fetch(:kraken_open_orders, expires_in: CACHE_EXPIRATION_DELAY.seconds, force: force_fetch) do
      client.private.open_orders.open
    end
  end

  def closed_orders
    client.private.closed_orders.closed
  end

  def recent_orders
    open_orders.merge(closed_orders)
  end

  def cache_open_order(order)
    cached_orders = Rails.cache.read(:kraken_open_orders)
    if cached_orders
      cached_orders.merge!(order)
      Rails.cache.write(:kraken_open_orders, cached_orders, expires_in: CACHE_EXPIRATION_DELAY.seconds)
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
    BigDecimal.new(balance.try(:ZEUR) || '0')
  end

  def balance_btc
    BigDecimal.new(balance.try(:XXBT)|| '0')
  end

  def cancel_order(order)
    Rails.cache.delete(:kraken_balance)
    client.delete("user/orders/#{order['uuid']}/cancel")
  end

  def place_order(type: :market, direction:, btc_amount:, price: nil, nb_retry:3)
    order = {
        pair: 'XXBTZEUR',
        type: direction.to_s,
        ordertype: type.to_s,
        volume: btc_amount
    }
    order.merge!(price: price) if type != :market

    res = client.private.add_order(order)

    cache_open_order(Hashie::Mash.new(res.txid[0] => Hashie::Mash.new(vol: btc_amount.to_s, descr: Hashie::Mash.new(order))))
    res.txid[0]

  rescue => e
    Rails.logger.warn("An #{e.class} exception occured while trying to place order: #{e.message}")
    if nb_retry > 0
      nb_retry = nb_retry - 1
      retry
    else
      raise
    end
  end

  private


  class AdjustedBalance
    def initialize(kraken_balance, open_orders)
      @balance = kraken_balance.dup
      @open_orders = open_orders.dup
      adjust_balance
    end

    def balance
      @balance
    end

    private

    def adjust_balance
      @open_orders.each do |_key, order|
        if order.descr.type == 'buy'
          update_balance(:eur, buy_order_estimated_cost(type: order.descr.ordertype.to_sym, price: order.descr.price.to_f, btc_amount: BigDecimal.new(order.vol)))
        else
          update_balance(:btc, -BigDecimal.new(order.vol))
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
          - asks_price(btc_amount) * btc_amount
        when :limit
          - price*btc_amount
        else
          raise "unknown order type #{type}"
      end
    end
  end


end