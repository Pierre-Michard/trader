require 'singleton'

class KrakenService
  include Singleton

  BALANCE_EXPIRATION_DELAY=30.seconds

  CONFIG = YAML.load(File.read(Rails.root.join('config', 'secret', 'kraken.yml'))).with_indifferent_access

  attr_reader :client

  def initialize
    KrakenClient.configure do |config|
      config.api_key     = CONFIG[:token]
      config.api_secret  = CONFIG[:secret]
      config.base_uri    = 'https://api.kraken.com'
    end
    @client = KrakenClient.load
  end

  def current_price
    client.public.ticker('XXBTZEUR')['XXBTZEUR'].c[0].to_f
  end

  def balance(force_fetch: false)
    Rails.cache.fetch(:kraken_balance, expires_in: BALANCE_EXPIRATION_DELAY.seconds, force: force_fetch) do
      client.private.balance
    end
  end

  def opened_orders(force_fetch: false)
    Rails.cache.fetch(:kraken_opened_orders, expires_in: BALANCE_EXPIRATION_DELAY.seconds, force: force_fetch) do
      client.private.open_orders.open
    end
  end

  def open_orders?(force_fetch: false)
    Rails.cache.fetch(:kraken_is_order_opened, expires_in: BALANCE_EXPIRATION_DELAY.seconds, force: force_fetch) do
      not client.private.open_orders.open.count.zero?
    end
  end

  def balance_eur
    balance.try(:ZEUR).to_f || 0
  end

  def balance_btc
    balance.try(:XXBT).to_f || 0
  end

  def update_cached_balance(currency, diff)
    cached_balance = Rails.cache.read(:kraken_balance)
    if cached_balance
      key = translate_currency(currency)
      cached_balance[key] = (cached_balance[key].to_f + diff).to_s
      Rails.cache.write(:kraken_balance, cached_balance, expires_in: BALANCE_EXPIRATION_DELAY.seconds)
    end
  end


  def cancel_order(order)
    Rails.cache.delete(:kraken_balance)
    client.delete("user/orders/#{order['uuid']}/cancel")
  end

  def place_market_order(direction:, btc_amount:, nb_retry:3)
    if direction == :buy
      update_cached_balance(:eur, -KrakenSdepthService.asks_price(btc_amount))
    else
      update_cached_balance(:btc, -btc_amount)
    end
    res = client.private.add_order({
       pair: 'XXBTZEUR',
       type: direction.to_s,
       ordertype: 'market',
       volume: btc_amount
    })

    Rails.cache.write(:kraken_is_order_opened, true, expires_in: BALANCE_EXPIRATION_DELAY.seconds)

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