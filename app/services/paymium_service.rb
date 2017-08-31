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

  def user(force_fetch: false)
    Rails.cache.fetch(:paymium_user, expires_in: 60.seconds, force: force_fetch) do
      client.get('/user').with_indifferent_access
    end
  end

  def update_user(user)
    cached = Rails.cache.read(:paymium_user)
    if cached
      Rails.cache.write(:paymium_user, cached.merge(user),expires_in: 60.seconds)
    end
  end

  def balance_eur
    user['balance_eur']
  end

  def locked_btc
    user['locked_btc']
  end

  def balance_btc
    user['balance_btc']
  end

  def locked_eur
    user['locked_eur']
  end

  def current_orders(force_fetch: false)
    Rails.cache.fetch(:current_orders, expires_in: 60.seconds, force: force_fetch) do
      client.get('user/orders', {'types[]': 'LimitOrder', active: true}).map{|o| o.with_indifferent_access}
    end
  end

  def update_cache
    Rails.logger.warn('Update Paymium user cache')
    current_orders(force_fetch:true)
    user(force_fetch:true)
    orders(force_fetch: true)
  end

  def current_sell_orders
    current_orders.select{|o| o['direction'] == 'sell'}
  end

  def current_buy_orders
    current_orders.select{|o| o['direction'] == 'buy'}
  end

  def orders(force_fetch: false)
    Rails.cache.fetch(:orders, expires_in: 60.seconds, force: force_fetch) do
      client.get('user/orders', {'types[]': ['LimitOrder']}).map{|o| o.with_indifferent_access}
    end
  end

  def order(order_uuid)
    client.get("user/orders/#{order_uuid}").with_indifferent_access
  end

  def extract_trades(from_orders:)
    from_orders.
        map{|o| o['account_operations'].map{|ao| ao.merge({'order' => o})}}.
        flatten.
        each_cons(2).
        select{|prev, ao| ['btc_purchase','btc_sale'].include?(ao['name']) && ao['currency'] == 'BTC'}.
        map do |prev, ao|
      {
          created_at:Time.parse(ao['created_at']),
          created_at_int: ao['created_at_int'],
          uuid:ao['uuid'],
          amount:ao['amount'],
          direction: ao['name'] == 'btc_purchase'? :buy : :sell,
          currency: 'BTC',
          order: ao['order'],
          counterpart: prev
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
    Rails.cache.delete(:paymium_user)
    Rails.cache.delete(:current_orders)
    client.delete("user/orders/#{order['uuid']}/cancel")
  end

  def cancel_all_orders
    current_orders(force_fetch:true).each do |o|
      p "cancel order #{o}"
      cancel_order(o)
    end
  end

  def place_limit_order(direction:, btc_amount:, price:)
    Rails.cache.delete(:paymium_user)
    Rails.cache.delete(:current_orders)
    client.post('user/orders', {
        type: 'LimitOrder',
        currency: 'EUR',
        direction: direction,
        amount: btc_amount,
        price: price.round(2)
    })
  end

  def sdepth(force: false)
    Rails.cache.fetch(:paymium_sdepth, expires_in: 60.seconds, force: force) do
      res = client.get('data/eur/depth').with_indifferent_access
      res[:bids] = res[:bids].reverse
      res
    end
  end

  def update_asks(asks)
    new_sdepth = sdepth
    asks.each do |ask|
      existing = new_sdepth[:asks].detect{ |el| el[:price] == ask[:price] }
      if ask[:amount] == 0
        new_sdepth[:asks].delete(existing) unless existing.nil?
      elsif existing.nil?
        (new_sdepth[:asks] << ask).sort_by! { |a| a[:price]}
      else
        existing[:amount] = ask[:amount]
      end
    end
    update_sdepth(new_sdepth)
  end

  def update_bids(bids)
    new_sdepth = sdepth
    bids.each do |bid|
      existing = new_sdepth[:bids].detect{ |el| el[:price] == bid[:price] }
      if bid[:amount] == 0
        new_sdepth[:bids].delete(existing) unless existing.nil?
      elsif existing.nil?
        (new_sdepth[:bids] << bid).sort_by! { |a| -a[:price]}
      else
        existing[:amount] = bid[:amount]
      end
    end
    update_sdepth(new_sdepth)
  end

  def update_sdepth(new_sdepth)
    first_bid = bids.first
    first_ask = asks.first
    if (!first_bid[:mine] && new_sdepth[:bids].first[:amount] != first_bid[:amount]) ||
        (!first_ask[:mine] && new_sdepth[:asks].first[:amount] != first_ask[:amount])
      MonitorPriceJob.perform_later
    end

    Rails.cache.write(:paymium_sdepth, new_sdepth, expires_in: 60.seconds)
  end

  def bids
    my_orders = current_buy_orders
    sdepth[:bids].each do |bid|
      bid[:mine] = my_orders.any?{|o| o[:price] == bid[:price]}
    end
  end

  def highest_stranger_bid(lower_than)
    bids.detect{|b| (not b[:mine]) && b[:price]< lower_than}
  end

  def highest_stranger_ask(higher_than)
    asks.detect{|b| not b[:mine] && b[:price]> higher_than}
  end

  def asks
    sdepth[:asks].each do |ask|
      ask[:mine] = current_sell_orders.any?{|o| o[:price] == ask[:price]}
    end
  end
end