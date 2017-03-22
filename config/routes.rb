require 'resque/server'

Rails.application.routes.draw do
  resources :users
  root to: "home#index"
  mount Resque::Server.new, :at => "/resque"
end
