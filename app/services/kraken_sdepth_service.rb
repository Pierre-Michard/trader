class KrakenSdepthService
  KEY = 'kraken_sdepth' # redis key

  class OutdatedData < Exception

  end

  def self.get
    sdepth = JSON.parse($redis.get(KEY)).with_indifferent_access
    sdepth[:now] = Time.at(sdepth[:now])
    unless sdepth[:now] > 1.minutes.ago
      raise OutdatedData.new 'no recent sdepth available'
    end
    sdepth
  end

  def self.set(sdepth)
    $redis.set(KEY, sdepth)
  end

  def self.asks
    asks = get[:return][:asks]
    if asks
      asks.map{|ask| {price: ask[0], amount: ask[1]}}
    else
      []
    end
  end

  def self.bids
    bids = get[:return][:bids]
    if bids
      bids.map{|bid| {price: bid[0], amount: bid[1]}}
    else
      []
    end
  end

  def self.bids_price(btc_amount = 1)
    virtual_price(bids, btc_amount)
  end

  def self.asks_price(btc_amount = 1)
    virtual_price(asks, btc_amount)
  end

  private
  def self.virtual_price(offers, btc_amount)
    rest = btc_amount
    price = 0
    offers.each do |offer|
      if rest > 0
        amount = [offer[:amount], rest].min
        price += offer[:price]*amount/btc_amount
        rest -= amount
      end
    end
    if rest <= 0
      price
    else
      offers[-1][:price]
    end
  end

end