class Trade < ApplicationRecord
  include AASM

  attr_accessor :kraken_remote_order

  scope :missed_orders, -> { where(created_at: 30.minutes.ago..1.minute.ago, aasm_state: :created)}

  validates :btc_amount,          presence: true
  validates :paymium_uuid,        presence: true
  validates :paymium_cost,        presence: true
  validates :paymium_price,       presence: true
  validates :paymium_order_uuid,  presence: true

  aasm :requires_lock => true do
    state :created, :inital => true
    state :kraken_order_placed,     before_enter: :place_counterpart_order
    state :ignored
    state :closed,                  before_enter: :set_kraken_info
    state :failed

    event :place_kraken_order do

      transitions :from => :created,
                  :to => :ignored,
                  :guard => [:amount_too_low?]

      transitions :from => :created,
                  :to => :kraken_order_placed
    end

    event :close do
      transitions :from => :kraken_order_placed,
                  :to => :closed,
                  :guard => [:kraken_order_closed?]

      transitions :from => :kraken_order_placed,
                  :to => :failed,
                  :guard => [:kraken_order_canceled?]
    end

  end

  after_commit on: :create do
    place_kraken_order! if may_place_kraken_order?
  end

  def amount_too_low?
    btc_amount.abs < 0.002
  end

  def place_counterpart_order
    unless Rails.env.development? or self.kraken_uuid.present?
      logger.info "place kraken market order #{btc_amount}"
      self.kraken_uuid = KrakenService.instance.place_order(
          type: :market,
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
    res = KrakenService.instance.client.private.query_orders(txid: kraken_uuid, trades: true)
    @kraken_remote_order = res[kraken_uuid]
  end

  def kraken_status
    kraken_remote_order.status
  end

  def kraken_order_closed?
    kraken_remote_order.try(:status) == 'closed'
  end

  def kraken_order_canceled?
    kraken_remote_order.try(:status) == 'canceled'
  end

  def set_kraken_info
    if kraken_order_closed?
      self.kraken_price = kraken_remote_order.price.to_f
      self.kraken_fee   = kraken_remote_order.fee.to_f
      self.kraken_cost  = (kraken_direction == :buy)? - kraken_remote_order.cost.to_f : kraken_remote_order.cost.to_f
    end
  end

  def eur_margin
    if kraken_cost.present? && paymium_cost.present? && kraken_fee.present?
      kraken_cost + paymium_cost - kraken_fee
    end
  end

  def percent_margin
    if kraken_price.present? && paymium_price.present?
      100 * (kraken_price - paymium_price).abs / paymium_price
    end
  end

  def set_kraken_info!
    set_kraken_info
    save!
  end


  def paymium_remote_order
    @paymium_remote_order ||= PaymiumService.instance.order(paymium_order_uuid)
  end

  def self.set_kraken_info
    Trade.where(kraken_cost: nil).where.not(kraken_uuid: nil).pluck(:kraken_uuid).each_slice(20) do |kraken_uuids|
      begin
        kraken_orders = KrakenService.instance.client.private.query_orders(txid: kraken_uuids.join(','))
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

  def fix_order!
    key, value = self.class.recent_unmatched_orders
                  .detect do |_key, value|
                    ((BigDecimal(value.vol) == btc_amount.abs) &&
                     (value.descr.type == (btc_amount > 0) ? 'sell':'buy' ))
    end

    if key.nil?
      place_kraken_order!
    else
      update_attributes(aasm_state: :kraken_order_placed, kraken_uuid: key)
      @kraken_remote_order = value
      close!
    end
  end

  def self.recent_unmatched_orders
    @recent_unmatched_orders ||= begin
      recent_orders = KrakenService.instance.recent_orders
      matched_keys = self.where(kraken_uuid: recent_orders.keys).pluck(:kraken_uuid)
      recent_orders
          .reject{|key, value| matched_keys.include? key}
          .reject{|key, value| Time.at(value.opentm) < 1.day.ago || value.descr.ordertype != 'market'}
    end
  end

  def self.fix_missed_orders!
    @recent_unmatched_orders = nil
    missed_orders.find_each do |t|
      t.fix_order!
    end
  end

  def self.close_orders
    Trade.where(aasm_state: :kraken_order_placed).find_each do |t|
      t.close! if t.may_close?
    end
  end

end
