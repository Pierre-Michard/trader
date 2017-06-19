class MonitorTradesJob < ApplicationJob
  queue_as :trader

  def perform
    robot = Robot.new
    robot.monitor_trades
    Trade.close_orders
  end
end
