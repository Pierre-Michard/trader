class HomeController < ApplicationController
  def index
    @messages = RecentPaymiumUserMessages.list
  end
end