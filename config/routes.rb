require 'resque/server'
require 'resque/scheduler/server'

Rails.application.routes.draw do
  get 'paymium_service/sdepth'

  resources :trades, only: :index
  get 'trades/graph'


  get 'stats/balance'
  get 'stats/marge'


  root to: "home#index"
  mount Resque::Server.new, :at => "/resque"
end
