require 'singleton'

class Kraken
  include Singleton

  CONFIG = YAML.load(File.read(Rails.root.join('config', 'secret', 'kraken.yml'))).with_indifferent_access

  attr_reader :client

  def initialize
    KrakenClient.configure do |config|
      config.api_key     = CONFIG[:token]
      config.api_secret  = CONFIG[:secret]
      config.base_uri    = 'https://api.kraken.com'
    end
    @client = KrakenClient.load
  end

  def current_price
    client.public.ticker('XXBTZEUR')['XXBTZEUR'].c[0].to_f
  end

  def balance
    client.private.balance
  end


end