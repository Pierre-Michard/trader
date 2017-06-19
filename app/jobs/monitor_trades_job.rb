class MonitorTradesJob < ApplicationJob
  @queue='trader'
  def perform
    robot = Robot.new
    robot.monitor_trades
    Trade.close_orders
  end
end
