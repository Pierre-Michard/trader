module WithSdepth
  extend ActiveSupport::Concern

  def sdepth_key
    "#{self.class.name}::sdepth"
  end

  class OutdatedData < Exception

  end

  def sdepth(force_fetch: false)
    Rails.cache.fetch(sdepth_key, expires_in: 10.seconds, force: force_fetch) do
      orderbook
    end
  end

  def asks
    sdepth[:asks]
  end

  def bids
    sdepth[:bids]
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