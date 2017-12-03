class TradesController < ApplicationController
  def index
    @trades = Trade.paginate(:page => params[:page]).order('id DESC')
  end

  def graph
    @period = graph_params.fetch(:period, 'day')
    @trades = case @period
        when 'hour'
          Trade.where('created_at > ?', 1.week.ago).group_by_hour(:created_at)
        when 'day'
          Trade.where('created_at > ?', 2.months.ago).group_by_day(:created_at)
        when 'week'
          Trade.where('created_at > ?', 1.year.ago).group_by_week(:created_at)
        when 'month'
          Trade.group_by_month(:created_at)
    end

    @volume = @trades.sum('ABS(btc_amount)')
    @wins   = @trades.sum('paymium_cost + counter_order_cost - counter_order_fee')
  end

  private

  def graph_params
    params.permit('period')
  end

end
