class Trade < ApplicationRecord
  validates :btc_amount, presence: true
  validates :paymium_uuid, presence: true

  after_create do
    logger.info "place kraken market order #{btc_amount}"
    unless Rails.env.development?
      self.kraken_uuid = Kraken.instance.place_market_order(
          direction:  (btc_amount > 0)? :sell : :buy,
          btc_amount: btc_amount.abs)
    end
    self.save!
  end

  def get_kraken_order
    Kraken.instance.client.private.query_orders(txid: kraken_uuid, trades: true)
  end
end
