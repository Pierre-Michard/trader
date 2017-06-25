require 'singleton'

class KrakenService
  include Singleton

  CACHE_EXPIRATION_DELAY=30.seconds

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
    Rails.cache.fetch(:kraken_balance, expires_in: CACHE_EXPIRATION_DELAY.seconds, force: force_fetch) do
      balance = client.private.balance
      AdjustedBalance.new(balance, open_orders).balance
    end
  end

  def open_orders(force_fetch: false)
    Rails.cache.fetch(:kraken_open_orders, expires_in: CACHE_EXPIRATION_DELAY.seconds, force: force_fetch) do
      client.private.open_orders.open
    end
  end

  def cache_open_order(order)
    cached_orders = Rails.cache.read(:kraken_open_orders)
    if cached_orders
      cached_orders.merge!(order)
      Rails.cache.write(:kraken_open_orders, cached_orders, expires_in: CACHE_EXPIRATION_DELAY.seconds)
    end

    cached_balance = Rails.cache.read(:kraken_balance)
    if cached_balance
      Rails.cache.write(:kraken_balance,
                        AdjustedBalance.new(cached_balance, order).balance,
                        expires_in: CACHE_EXPIRATION_DELAY.seconds)
    end
  end

  def update_cache
    Rails.logger.warn('Update kraken cache')
    open_orders(force_fetch: true)
    unless open_orders?
      Rails.logger.warn('Update kraken balance')
      balance(force_fetch: false)
    end
  end

  def open_orders?
    not open_orders.count.zero?
  end

  def balance_eur
    balance.try(:ZEUR).to_f || 0
  end

  def balance_btc
    balance.try(:XXBT).to_f || 0
  end

  def cancel_order(order)
    Rails.cache.delete(:kraken_balance)
    client.delete("user/orders/#{order['uuid']}/cancel")
  end

  def place_order(type: :market, direction:, btc_amount:, price:, nb_retry:3)
    order = {
        pair: 'XXBTZEUR',
        type: direction.to_s,
        ordertype: type.to_s,
        volume: btc_amount
    }
    order.merge!(price: price) if type != :market

    res = client.private.add_order(order)

    cache_open_order(Hashie::Mash.new(res.txid[0] => Hashie::Mash.new(order)))
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

  def buy_order_estimated_cost(type:, price:, btc_amount:)
    case type
      when :market
        - KrakenSdepthService.asks_price(btc_amount)
      when :limit
        - price*btc_amount
      else
        raise "unknown order type #{type}"
    end
  end


  class AdjustedBalance
    def initialize(kraken_balance, open_orders)
      @balance = kraken_balance.dup
      @open_orders = open_orders.dup
    end

    def balance
      @balance
    end

    private

    def adjust_balance
      @open_orders.each do |_key, order|
        if order.direction == 'buy'
          update_balance(:eur, buy_order_estimated_cost(type: order.type.to_sym, price: order.price.to_f, btc_amount: order.volume.to_f))
        else
          update_balance(:btc, -order.volume.to_f)
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
  end


end