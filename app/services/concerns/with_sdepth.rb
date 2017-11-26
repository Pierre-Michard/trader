module WithSdepth
  extend ActiveSupport::Concern

  def sdepth_key
    "#{self.class.name}::sdepth"
  end

  class OutdatedData < Exception

  end

  def get_sdepth
    sdepth = JSON.parse($redis.get(sdepth_key)).with_indifferent_access
    sdepth[:now] = Time.at(sdepth[:now])
    unless sdepth[:now] > 1.minutes.ago
      raise OutdatedData.new 'no recent sdepth available'
    end
    sdepth[:sdepth]
  end

  def set_sdepth(sdepth)
    $redis.set(sdepth_key, sdepth)
  end

  def asks
    get_sdepth[:asks]
  end

  def bids
    get_sdepth[:bids]
  end

  def bids_price(btc_amount = 1)
    virtual_price(bids, btc_amount)
  end

  def asks_price(btc_amount = 1)
    virtual_price(asks, btc_amount)
  end

  private
  def virtual_price(offers, btc_amount)
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