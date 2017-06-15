class Trade < ApplicationRecord
  validates :btc_amount, presence: true
  validates :paymium_uuid, presence: true

  after_commit on: :create do
    logger.info "place kraken market order #{btc_amount}"
    unless Rails.env.development? or self.kraken_uuid.present?
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

  def kraken_status
    kraken_remote_order.status
  end

  def kraken_remote_price
    kraken_order = kraken_remote_order
    if kraken_order.try(:status) == 'closed'
      kraken_order.price.to_f
    end
  end

  def set_kraken_info!(remote_order=nil)
    kraken_order = remote_order || kraken_remote_order
    if kraken_order.try(:status) == 'closed'
      self.kraken_price = kraken_order.price.to_f
      self.kraken_fee =   kraken_order.fee.to_f
      self.kraken_cost =  kraken_order.cost.to_f
      save!
    end
  end

  def self.set_kraken_info
    Trade.where(kraken_cost: nil).where.not(kraken_uuid: nil).pluck(:kraken_uuid).each_slice(20) do |kraken_uuids|
      begin
        kraken_orders = Kraken.instance.client.private.query_orders(txid: kraken_uuids.join(','))
        kraken_orders.each do |kraken_uuid, kraken_order|
          Rails.logger.info("update trade #{kraken_uuid}")
          trade = Trade.find_by(kraken_uuid: kraken_uuid)
          trade.set_kraken_info!(kraken_order)
        end

        #t.set_kraken_info!
      rescue => e
        Rails.logger.error("#{e.class} raised when setting kraken info for order #{kraken_uuids}")
      end
    end
  end

end
