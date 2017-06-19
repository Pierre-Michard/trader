require 'resque/server'

Rails.application.routes.draw do
  get 'paymium_service/sdepth'

  resources :users
  root to: "home#index"
  mount Resque::Server.new, :at => "/resque"
end
