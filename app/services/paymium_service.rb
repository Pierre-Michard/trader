require 'singleton'
require 'lock'

class PaymiumService
  include Singleton
  include Retriable

  CONFIG = YAML.load(File.read(Rails.root.join('config', 'secret', 'paymium.yml'))).with_indifferent_access
  CURRENT_ORDERS_CACHE_DELAY = 20.seconds

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
      get('/user')
    end
  end

  def update_user(user)
    cached = Rails.cache.read(:paymium_user)
    if cached
      Rails.cache.write(:paymium_user, cached.merge(user),expires_in: 60.seconds)
    end
  end

  def balance_eur
    user['balance_eur'].to_d
  end

  def locked_btc
    user['locked_btc'].to_d
  end

  def balance_btc
    user['balance_btc'].to_d
  end

  def locked_eur
    user['locked_eur'].to_d
  end

  def current_orders(force_fetch: false)
    Rails.cache.fetch(:current_orders, expires_in: CURRENT_ORDERS_CACHE_DELAY, force: force_fetch) do
      get('user/orders', {'types[]': 'LimitOrder', active: true})
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
      get('user/orders', {'types[]': ['LimitOrder']})
    end
  end

  def order(order_uuid)
    get("user/orders/#{order_uuid}")
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
          amount:ao['amount'].to_d,
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


  def current_orders_descr
    str = current_orders.map do |order|
      "#{order[:created_at]} #{order[:uuid]}: #{order[:direction]} #{order[:amount].to_f.round(3)} #{order[:state]}"
    end
    str.join("\n")
  end


  def cancel_order(order)
    Rails.logger.info "cancel order #{order['uuid']}"
    with_retries(nb_retries: 1) do
      client.delete("user/orders/#{order['uuid']}/cancel")
    end
    Rails.cache.write(:current_orders, current_orders.select{|o| o['uuid'] != order['uuid']}, expires_in: CURRENT_ORDERS_CACHE_DELAY)
  end

  def cancel_all_orders
    current_orders(force_fetch:true).each do |o|
      cancel_order(o)
    end
  end

  def place_limit_order(direction:, btc_amount:, price:)
    with_retries(nb_retries: 1) do
      res = post('user/orders', {
          type: 'LimitOrder',
          currency: 'EUR',
          direction: direction,
          amount: btc_amount.to_s,
          price: price.round(2).to_s
      })
      Rails.cache.write(:current_orders, current_orders.push(res.with_indifferent_access), expires_in: CURRENT_ORDERS_CACHE_DELAY)
    end
  end

  def sdepth(force: false)
    Rails.cache.fetch(:paymium_sdepth, expires_in: 10.seconds, force: force, race_condition_ttl:1.second) do
      res = get('data/eur/depth')
      res[:bids] = res[:bids].reverse
      res
    end
  end

  def update_asks(asks)
    new_sdepth = sdepth
    asks.each do |ask|
      existing = new_sdepth[:asks].detect{ |el| el[:price].to_d == ask[:price].to_d }
      if ask[:amount].to_d == 0
        new_sdepth[:asks].delete(existing) unless existing.nil?
      elsif existing.nil?
        (new_sdepth[:asks] << ask).sort_by! { |a| a[:price].to_d}
      else
        existing[:amount].to_d = ask[:amount].to_d
      end
    end
    update_sdepth(new_sdepth)
  end

  def update_bids(bids)
    new_sdepth = sdepth
    bids.each do |bid|
      existing = new_sdepth[:bids].detect{ |el| el[:price].to_d == bid[:price].to_d }
      if bid[:amount].to_d == 0
        new_sdepth[:bids].delete(existing) unless existing.nil?
      elsif existing.nil?
        (new_sdepth[:bids] << bid).sort_by! { |a| -(a[:price].to_d)}
      else
        existing[:amount].to_d = bid[:amount].to_d
      end
    end
    update_sdepth(new_sdepth)
  end

  def update_sdepth(new_sdepth)
    first_bid = bids.first
    first_ask = asks.first
    if (first_bid[:mine] && new_sdepth[:bids].first[:amount].to_d != first_bid[:amount].to_d) ||
        (first_ask[:mine] && new_sdepth[:asks].first[:amount].to_d != first_ask[:amount].to_d)
      unless api_threshold_exceeded? || Resque.size('trader_production_trader') > 2
        MonitorPriceJob.perform_later
      end
    end

    Rails.cache.write(:paymium_sdepth, new_sdepth, expires_in: 10.seconds)
  end

  def bids
    my_orders = current_buy_orders
    sdepth[:bids].each do |bid|
      bid[:mine] = my_orders.any?{|o| o[:price].to_d == bid[:price].to_d}
    end
  end

  def highest_stranger_bid(lower_than)
    bids.detect{|b| (not b[:mine]) && b[:price].to_d < lower_than}
  end

  def highest_stranger_ask(higher_than)
    asks.detect{|b| (not b[:mine]) && b[:price].to_d > higher_than}
  end

  def asks
    sdepth[:asks].each do |ask|
      ask[:mine] = current_sell_orders.any?{|o| o[:price].to_d == ask[:price].to_d}
    end
  end

  def get(*args)
    res = Lock.acquire('paymium_client') do
      client.get(*args)
    end

    Rails.cache.write(:remaining_api_calls, client.remaining_limit, expires_in: 10.minutes)

    if res.is_a? Array
      res.map(&:with_indifferent_access)
    else
      res.with_indifferent_access
    end
  end

  def post(*args)
    res = Lock.acquire('paymium_client') do
      client.post(*args)
    end

    if res.is_a? Array
      res.map(&:with_indifferent_access)
    else
      res.with_indifferent_access
    end
  end

  def api_threshold_exceeded?
    if remaining_api_calls.nil?
      false
    else
      remaining_api_calls < api_current_threshold
    end
  end

  def api_current_threshold
    24.hours.to_i - Time.now.seconds_since_midnight
  end

  def remaining_api_calls
    Rails.cache.read(:remaining_api_calls)
  end
end