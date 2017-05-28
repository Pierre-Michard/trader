class UpdateTickerJob < ApplicationJob
  @queue='update_ticker'
  def perform
    robot = Robot.new
    robot.cleanup_orders
    begin
      robot.monitor_sell_price
      robot.monitor_buy_price
    rescue KrakenSdepthService::OutdatedData
      PaymiumService.instance.cancel_all_orders
    end
    robot.monitor_trades
  end
end
