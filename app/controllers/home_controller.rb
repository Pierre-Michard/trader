class HomeController < ApplicationController
  def index
    @robot = RobotService.new
    @trades = Trade.paginate(:page => params[:page]).order('id DESC')
    @stat = Stat.new
  end
end