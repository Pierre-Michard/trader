class User < ApplicationRecord
  def kraken_client
    @kraken_client ||= Kraken::Client.new(kraken_token, kraken_secret)
  end
end
