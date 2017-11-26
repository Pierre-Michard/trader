module WithPublicTrades
  extend ActiveSupport::Concern

  STORE_LIMIT = 5

  def list_trades(limit = STORE_LIMIT)
    $redis.lrange(public_trades_key, 0, limit-1).map do |raw_trade|
      trade = JSON.parse(raw_trade).with_indifferent_access
      trade[:date] = Time.at(trade[:timestamp].to_i)
      trade
    end
  end

  def last_trade
    list_trades[0]
  end

  def push_trade(raw_post)
    $redis.lpush(public_trades_key, raw_post)
    $redis.ltrim(public_trades_key, 0, STORE_LIMIT-1)
  end

  def public_trades_key
    "#{self.class.name}::trades"
  end
end