class UpdateTickerJob < ApplicationJob
  @queue='update_ticker'
  def perform
    robot = Robot.new
    #robot.cleanup_orders
    robot.monitor_trades
    robot.monitor_sell_price
    robot.monitor_buy_price
  end
end
