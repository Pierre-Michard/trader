class StatsController < ApplicationController
  def balance
    @period = params.fetch(:period, 'day')
    @stats = case @period
                when 'hour'
                  Stat.where('created_at > ?', 1.week.ago).group_by_hour(:created_at)
                when 'day'
                  Stat.where('created_at > ?', 2.months.ago).group_by_day(:created_at)
                when 'week'
                  Stat.where('created_at > ?', 1.year.ago).group_by_week(:created_at)
                when 'month'
                  Stat.group_by_month(:created_at)
              end

    @eur_balance = @stats.average('paymium_eur_balance + kraken_eur_balance')
    @btc_balance = @stats.average('paymium_btc_balance + kraken_btc_balance')
  end

  def marge
    @period = params.fetch(:period, 'day')
    @stats = case @period
       when 'hour'
         Stat.where('created_at > ?', 1.week.ago).group_by_hour(:created_at)
       when 'day'
         Stat.where('created_at > ?', 2.months.ago).group_by_day(:created_at)
       when 'week'
         Stat.where('created_at > ?', 1.year.ago).group_by_week(:created_at)
       when 'month'
         Stat.group_by_month(:created_at)
     end
    @buy_marge  = @stats.average('(paymium_best_bid - kraken_best_ask) / price')
    @sell_marge = @stats.average('(paymium_best_ask - kraken_best_bid) / price')
    @paymium_best_bid  = @stats.average('paymium_best_bid - kraken_best_ask')
    @paymium_best_ask  = @stats.average('paymium_best_ask - kraken_best_ask')
    @kraken_best_ask  = @stats.average('kraken_best_ask - kraken_best_ask')
    @kraken_best_bid  = @stats.average('kraken_best_bid - kraken_best_ask')
  end
end
