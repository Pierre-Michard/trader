class MonitorTradesJob < ApplicationJob
  @queue='monitor_trades'
  def perform
    robot = Robot.new
    robot.monitor_trades
    Trade.close_orders
  end
end
