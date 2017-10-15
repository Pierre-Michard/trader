class TradesController < ApplicationController
  def index
    @trades = Trade.paginate(:page => params[:page]).order('id DESC')
  end
end
