require 'singleton'

class Kraken
  include Singleton

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

  def balance
    Rails.cache.fetch(:kraken_balance, expires_in: 2.seconds) do
      client.private.balance
    end
  end

  def open_orders?
    not client.private.open_orders.open.count.zero?
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

  def place_market_order(direction:, btc_amount:)
    res = client.private.add_order({
       pair: 'XXBTZEUR',
       type: direction.to_s,
       ordertype: 'market',
       volume: btc_amount
    })
    Rails.cache.delete(:kraken_balance)
    res.txid[0]
  end

end