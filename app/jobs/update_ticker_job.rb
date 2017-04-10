class UpdateTickerJob < ApplicationJob
  @queue='update_ticker'
  def perform
    Robot.instance.monitor_trades
    Robot.instance.monitor_sell_price
    Robot.instance.monitor_buy_price
  end
end
