class HomeController < ApplicationController
  def index
    @trades = Trade.limit(100).reverse_order
  end
end