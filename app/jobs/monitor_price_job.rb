class MonitorPriceJob < ApplicationJob
  queue_as :trader

  def perform
    robot = RobotService.new

    robot.monitor_trades
    begin
      robot.monitor_price(direction: :sell)
      robot.monitor_price(direction: :buy)
    rescue KrakenSdepthService::OutdatedData
      PaymiumService.instance.cancel_all_orders
    rescue Paymium::Api::Client::Error
      PaymiumService.instance.cancel_all_orders
      raise
    end
    robot.cleanup_orders
  end
end
