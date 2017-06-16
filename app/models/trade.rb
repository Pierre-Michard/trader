class Trade < ApplicationRecord
  include AASM

  attr_accessor :kraken_remote_order

  validates :btc_amount,    presence: true
  validates :paymium_uuid,  presence: true
  validates :paymium_cost,  presence: true
  validates :paymium_price, presence: true

  aasm :requires_lock => true do
    state :created, :inital => true
    state :kraken_order_placed,     before_enter: :place_counterpart_order
    state :closed,                  before_enter: :set_kraken_info

    event :place_kraken_order do
      transitions :from => :created,
                  :to => :kraken_order_placed
    end

    event :close do
      transitions :from => :kraken_order_placed,
                  :to => :closed,
                  :guard => [:kraken_order_closed?]
    end

  end

  after_commit on: :create do
    place_kraken_order! if may_place_kraken_order?
  end

  def place_counterpart_order
    unless Rails.env.development? or self.kraken_uuid.present?
      logger.info "place kraken market order #{btc_amount}"
      self.kraken_uuid = Kraken.instance.place_market_order(
          direction:  kraken_direction,
          btc_amount: btc_amount.abs)
    end
  end

  def kraken_direction
    (btc_amount > 0)? :sell : :buy
  end

  def paymium_direction
    (btc_amount > 0)? :buy : :sell
  end

  def kraken_remote_order
    return @kraken_remote_order if @kraken_remote_order
    res = Kraken.instance.client.private.query_orders(txid: kraken_uuid, trades: true)
    @kraken_remote_order = res[kraken_uuid]
  end

  def kraken_status
    kraken_remote_order.status
  end

  def kraken_order_closed?
    kraken_remote_order.try(:status) == 'closed'
  end

  def set_kraken_info
    if kraken_order_closed?
      self.kraken_price = kraken_remote_order.price.to_f
      self.kraken_fee   = kraken_remote_order.fee.to_f
      self.kraken_cost  = (kraken_direction == :buy)? - kraken_remote_order.cost.to_f : kraken_remote_order.cost.to_f
    end
  end

  def eur_margin
    self.kraken_cost + self.paymium_cost
  end

  def set_kraken_info!
    set_kraken_info
    save!
  end

  def self.set_kraken_info
    Trade.where(kraken_cost: nil).where.not(kraken_uuid: nil).pluck(:kraken_uuid).each_slice(20) do |kraken_uuids|
      begin
        kraken_orders = Kraken.instance.client.private.query_orders(txid: kraken_uuids.join(','))
        kraken_orders.each do |kraken_uuid, kraken_order|
          Rails.logger.info("update trade #{kraken_uuid}")
          trade = Trade.find_by(kraken_uuid: kraken_uuid)
          trade.kraken_remote_order =kraken_order
          trade.set_kraken_info!
        end

      rescue => e
        Rails.logger.error("#{e.class} raised when setting kraken info for order #{kraken_uuids}")
      end
    end
  end

end
