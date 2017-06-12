class MonitorTradesJob < ApplicationJob
  @queue='monitor_trades'
  def perform
    robot = Robot.new
    robot.monitor_trades
  end
end
