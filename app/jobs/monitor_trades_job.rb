class MonitorTradesJob < ApplicationJob
  queue_as :trader

  def perform
    robot = RobotService.new
    robot.monitor_trades
    Trade.close_orders

    Trade.
        where('created_at > ?', 30.minutes.ago).
        where('created_at < ?', 1.minutes.ago).
        where(aasm_state: 'created').
        find_each do |t|
      t.place_kraken_order!
    end
  end
end
