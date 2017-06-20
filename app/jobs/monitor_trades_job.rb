class MonitorTradesJob < ApplicationJob
  queue_as :trader

  def perform
    robot = RobotService.new
    robot.monitor_trades
    Trade.close_orders
  end
end
