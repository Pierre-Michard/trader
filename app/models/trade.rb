class Trade < ApplicationRecord
  validates :btc_amount, presence: true
  validates :paymium_uuid, presence: true

  after_create do
    p "place kraken market order #{btc_amount}"
    self.kraken_uuid = Kraken.instance.place_market_order(
        direction:  (btc_amount > 0)? :sell : :buy,
        btc_amount: btc_amount.abs)
    self.save!
  end

  def get_kraken_order
    Kraken.instance.client.private.query_orders(txid: kraken_uuid, trades: true)
  end
end
