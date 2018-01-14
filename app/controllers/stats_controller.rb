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

    @eur_balance = @stats.average('paymium_eur_balance + kraken_eur_balance + COALESCE(gdax_eur_balance, 0)')
    @btc_balance = @stats.average('paymium_btc_balance + kraken_btc_balance + COALESCE(gdax_btc_balance, 0)')
    @virtual_eur_balance = @stats.average('paymium_eur_balance + kraken_eur_balance + COALESCE(gdax_eur_balance, 0) + price * (paymium_btc_balance + kraken_btc_balance + COALESCE(gdax_btc_balance, 0))')
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

    @pk_buy_marge  = @stats.average('(paymium_best_bid - kraken_best_ask) / price')
    @pk_sell_marge = @stats.average('(paymium_best_ask - kraken_best_bid) / price')

    @pg_buy_marge  = @stats.average('(paymium_best_bid - gdax_best_ask) / price')
    @pg_sell_marge = @stats.average('(paymium_best_ask - gdax_best_bid) / price')

    @kg_buy_marge  = @stats.average('(kraken_best_bid - gdax_best_ask) / price')
    @kg_sell_marge = @stats.average('(kraken_best_ask - gdax_best_bid) / price')


    @paymium_best_bid  = @stats.average('paymium_best_bid - kraken_best_ask')
    @paymium_best_ask  = @stats.average('paymium_best_ask - kraken_best_ask')
    @kraken_best_ask  = @stats.average('kraken_best_ask - kraken_best_ask')
    @kraken_best_bid  = @stats.average('kraken_best_bid - kraken_best_ask')
    @gdax_best_ask  = @stats.average('gdax_best_ask - kraken_best_ask')
    @gdax_best_bid  = @stats.average('gdax_best_bid - kraken_best_ask')

    @hour_histo = Trade.where('created_at > ?', 2.months.ago).group("date_part('hour', created_at)").sum('abs(btc_amount)')
  end
end
