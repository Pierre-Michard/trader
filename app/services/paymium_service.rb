require 'singleton'

class PaymiumService
  include Singleton

  CONFIG = YAML.load(File.read(Rails.root.join('config', 'secret', 'paymium.yml'))).with_indifferent_access

  attr_reader :client

  def initialize
    @client = Paymium::Api::Client.new  host: 'https://sandbox.paymium.com/api/v1',
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

  def current_orders
    client.get('user/orders', {'types[]': 'LimitOrder', active: true})
  end

  def orders
    client.get('user/orders', {'types[]': ['MarketOrder', 'LimitOrder']})
  end

  def trades
    orders.
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

end
