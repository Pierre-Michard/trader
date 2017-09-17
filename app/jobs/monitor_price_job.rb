class MonitorPriceJob < ApplicationJob
  queue_as :trader

  after_exception do
    Rails.logger.error "Exception occured when updating price: #{current_exception}"
  end

  def perform
    robot = RobotService.new

    robot.monitor_trades
    PaymiumService.instance.current_orders(force_fetch:true)
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
