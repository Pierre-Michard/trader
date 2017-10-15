class TradesController < ApplicationController
  def index
    @trades = Trade.paginate(:page => params[:page])
  end
end
