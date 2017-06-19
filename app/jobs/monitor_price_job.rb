class MonitorPriceJob < ApplicationJob
  @queue='trader'
  def perform
    robot = Robot.new

    robot.monitor_trades
    begin
      robot.monitor_price(direction: :sell)
      robot.monitor_price(direction: :buy)
    rescue KrakenSdepthService::OutdatedData
      PaymiumService.instance.cancel_all_orders
    end
    robot.cleanup_orders
  end
end
