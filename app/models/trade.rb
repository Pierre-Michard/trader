class Trade < ApplicationRecord
  include AASM

  attr_accessor :counterpart_remote_order

  scope :missed_orders, -> { where(created_at: 30.minutes.ago..1.minute.ago, aasm_state: :created)}

  validates :btc_amount,          presence: true
  validates :paymium_uuid,        presence: true
  validates :paymium_cost,        presence: true
  validates :paymium_price,       presence: true
  validates :paymium_order_uuid,  presence: true

  aasm :requires_lock => true do
    state :created, :inital => true
    state :counter_order_placed,     before_enter: :place_counter_order
    state :ignored
    state :closed,                  before_enter: :set_counter_order_info
    state :failed

    event :place_counter_order do

      transitions :from => :created,
                  :to => :ignored,
                  :guard => [:amount_too_low?]

      transitions :from => :created,
                  :to => :counter_order_placed
    end

    event :close do
      transitions :from => :counter_order_placed,
                  :to => :closed,
                  :guard => [:counter_order_closed?]

      transitions :from => :counter_order_placed,
                  :to => :failed,
                  :guard => [:counter_order_canceled?]
    end

  end

  after_commit on: :create do
    place_counter_order! if may_place_counter_order?
  end

  def amount_too_low?
    btc_amount.abs < 0.002
  end

  def place_counter_order
    unless Rails.env.development? or self.counter_order_uuid.present?
      logger.info "place counter order #{btc_amount}"
      self.counter_order_uuid = Setting.counter_orders_service.place_order(
          type: :market,
          direction:  counter_order_direction,
          btc_amount: btc_amount.abs)
    end
  end

  def counter_order_direction
    (btc_amount > 0)? :sell : :buy
  end

  def paymium_direction
    (btc_amount > 0)? :buy : :sell
  end

  def remote_counter_order
    @remote_counter_order ||= Setting.counter_orders_service.order(counter_order_uuid)
  end

  def counter_order_status
    remote_counter_order[:status]
  end

  def counter_order_closed?
    remote_counter_order[:status] == :closed
  end

  def counter_order_canceled?
    remote_counter_order[:status] == :canceled
  end

  def set_counterpart_info
    if counter_order_closed?
      self.counter_order_price = remote_counter_order[:price]
      self.counter_order_fee   = remote_counter_order[:fee]
      self.counter_order_cost  = (counter_order_direction == :buy)? -remote_counter_order[:cost] : remote_counter_order[:cost]
    end
  end

  def eur_margin
    if counter_order_cost.present? && paymium_cost.present? && counter_order_fee.present?
      counter_order_cost + paymium_cost - counter_order_fee
    end
  end

  def percent_margin
    if counter_order_price.present? && paymium_price.present?
      100 * (counter_order_price - paymium_price).abs / paymium_price
    end
  end

  def set_counterpart_info!
    set_counterpart_info
    save!
  end


  def paymium_remote_order
    @paymium_remote_order ||= PaymiumService.instance.order(paymium_order_uuid)
  end

  def self.set_counterpart_info
    Trade.where(counter_order_cost: nil).where.not(counter_order_uuid: nil).pluck(:counter_order_uuid).each_slice(20) do |kraken_uuids|
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
                    ((BigDecimal(value.vol) == BigDecimal(btc_amount.to_s).abs) &&
                     (value.descr.type == (btc_amount > 0) ? 'sell':'buy' ))
    end

    if key.nil?
      place_kraken_order!
    else
      update_attributes(aasm_state: :kraken_order_placed, kraken_uuid: key)
      @counterpart_remote_order = value
      close!
    end
  end

  def self.recent_unmatched_orders
    @recent_unmatched_orders ||= begin
      recent_orders = Setting.counter_orders_service.recent_orders
      matched_keys = self.where(counter_order_uuid: recent_orders.keys).pluck(:counter_order_uuid)
      recent_orders
          .reject{|key, value| matched_keys.include? key}
          .reject{|key, value| value[:created_at] < 1.day.ago || value[:type] != 'market'}
    end
  end

  def self.fix_missed_orders!
    @recent_unmatched_orders = nil
    missed_orders.find_each do |t|
      t.fix_order!
    end
  end

  def self.close_orders
    Trade.where(aasm_state: :counter_order_placed).find_each do |t|
      t.close! if t.may_close?
    end
  end

end
