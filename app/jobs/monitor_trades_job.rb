class MonitorTradesJob < ApplicationJob
  queue_as :trader

  def perform
    robot = RobotService.new
    robot.monitor_trades
    Trade.fix_missed_orders!
    Trade.close_orders

  end

end
