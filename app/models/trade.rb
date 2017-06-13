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

  def kraken_remote_order
    res = Kraken.instance.client.private.query_orders(txid: kraken_uuid, trades: true)
    res[kraken_uuid]
  end

  def kraken_price
    self[:kraken_price] || set_kraken_price!
  end

  def kraken_status
    kraken_remote_order.status
  end

  def kraken_remote_price
    kraken_order = kraken_remote_order
    if kraken_order.try(:status) == 'closed'
      kraken_order.price.to_f
    end
  end

  def set_kraken_price!
    self.kraken_price = kraken_remote_price
    save!
    kraken_price
  end

  def self.set_kraken_price
    Trade.where(kraken_price: nil).where.not(kraken_uuid: nil).find_each do |t|
      begin
        t.set_kraken_price!
      rescue => e
        Rails.logger.error("#{e.class} raised when setting kraken price for order #{t.uuid}")
      end
    end
  end

end
