require 'resque/server'
require 'resque/scheduler/server'

Rails.application.routes.draw do
  get 'paymium_service/sdepth'

  resources :trades, only: :index
  get 'trades/graph'


  root to: "home#index"
  mount Resque::Server.new, :at => "/resque"
end
