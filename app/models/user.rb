

class User < ApplicationRecord


  def configure_kraken
    KrakenClient.configure do |config|
      config.api_key     = kraken_token
      config.api_secret  = kraken_secret
      config.base_uri    = 'https://api.kraken.com'
      config.api_version = 0
      config.limiter     = true
      config.tier        = 2
    end
    KrakenClient.load
  end

  def kraken_client
    @kraken_client ||= configure_kraken
  end
end
