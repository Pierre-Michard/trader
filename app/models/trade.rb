class Trade < ApplicationRecord
  validates :btc_amount, presence: true
  validates :paymium_uuid, presence: true

  after_create do
    p "place kraken market order #{btc_amount}"
    self.kraken_uuid = Kraken.instance.place_market_order(
        direction:  (btc_amount > 0)? :sell : :buy,
        btc_amount: btc_amount.abs)
  end
end
