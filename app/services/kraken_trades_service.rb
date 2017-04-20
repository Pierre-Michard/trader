class KrakenTradesService
  KEY = 'kraken_trades'
  STORE_LIMIT = 5

  def self.list(limit = STORE_LIMIT)
    $redis.lrange(KEY, 0, limit-1).map do |raw_trade|
      trade = JSON.parse(raw_trade).with_indifferent_access
      trade[:date] = Time.at(trade[:date])
      trade
    end
  end

  def self.push(raw_post)
    $redis.lpush(KEY, raw_post)
    $redis.ltrim(KEY, 0, STORE_LIMIT-1)
  end
end