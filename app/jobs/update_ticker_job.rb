class UpdateTickerJob < ApplicationJob
  @queue='update_ticker'
  def perform
    robot = Robot.new
    begin
      robot.monitor_price(direction: :sell)
      robot.monitor_price(direction: :buy)
    rescue KrakenSdepthService::OutdatedData
      PaymiumService.instance.cancel_all_orders
    end
    robot.monitor_trades
    robot.cleanup_orders
  end
end
