class UpdateTicker < ApplicationJob
  @queue='update_ticker'
  def self.perform
    logger.warn User.last.kraken_client.ticker('BTCEUR')
  end
end
