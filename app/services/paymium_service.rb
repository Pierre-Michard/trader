require 'singleton'

class PaymiumService
  include Singleton

  CONFIG = YAML.load(File.read(Rails.root.join('config', 'secret', 'paymium.yml'))).with_indifferent_access

  attr_reader :client

  def initialize
    @client = Paymium::Api::Client.new  host: 'https://paymium.com/api/v1',
                                        key: CONFIG[:token],
                                        secret: CONFIG[:secret]

  end

  def broadcast_channel_id
    conn = Bunny.new(:automatically_recover => false)
    conn.start

    ch   = conn.create_channel
    q    = ch.queue('paymium_cmd', :durable => true, :auto_delete => false)

    ch.default_exchange.publish(user['channel_id'], :routing_key => q.name)
    puts " [x] Sent #{user['channel_id']}"

    conn.close
  end

  def user
    client.get('/user')
  end

  def balance_eur
    user['balance_eur']
  end

  def balance_btc
    user['balance_btc']
  end

  def current_orders
    client.get('user/orders', {'types[]': 'LimitOrder', active: true}).map{|o| o.with_indifferent_access}
  end

  def current_sell_orders
    current_orders.select{|o| o['direction'] == 'sell'}
  end

  def current_buy_orders
    current_orders.select{|o| o['direction'] == 'buy'}
  end

  def orders
    client.get('user/orders', {'types[]': ['LimitOrder']}).map{|o| o.with_indifferent_access}
  end

  def extract_trades(from_orders:)
    from_orders.
        map{|o| o['account_operations']}.
        flatten.
        select{|ao| ['btc_purchase','btc_sale'].include?(ao['name']) && ao['currency'] == 'BTC'}.
        map do |ao|
      {
          created_at:Time.parse(ao['created_at']),
          uuid:ao['uuid'],
          amount:ao['amount'],
          direction: ao['name'] == 'btc_purchase'? :buy : :sell,
          currency: 'BTC'
      }
    end
  end

  def trades
    extract_trades(from_orders:orders)
  end

  def latest_trades(newer_than: 1.hour)
    trades.select{|t| t[:created_at] > newer_than.ago}
  end

  def latest_sell_trades(newer_than: 1.hour)
    latest_trades(newer_than: newer_than).select{|t| t[:direction] == :sell}
  end

  def latest_buy_trades(newer_than: 1.hour)
    latest_trades(newer_than: newer_than).select{|t| t[:direction] == :buy}
  end

  def cancel_order(order)
    client.delete("user/orders/#{order['uuid']}/cancel")
  end

  def cancel_all_orders
    current_orders.each{|o| cancel_order(o)}
  end

  def place_limit_order(direction:, btc_amount:, price:)
    client.post('user/orders', {
        type: 'LimitOrder',
        currency: 'EUR',
        direction: direction,
        amount: btc_amount,
        price: price.round(2)
    })
  end

end