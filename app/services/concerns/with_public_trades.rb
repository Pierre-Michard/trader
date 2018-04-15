module WithPublicTrades
  extend ActiveSupport::Concern

  def last_trade(force_fetch: false)
    Rails.cache.fetch(public_trades_key, expires_in: 10.seconds, force: force_fetch) do
      get_last_trade
    end
  end

  def public_trades_key
    "#{self.class.name}::trades"
  end
end