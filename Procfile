web: bundle exec rails server -p $PORT
paymium_private_node: nodejs node/paymium_private.js
kraken_public_node: nodejs node/kraken_public.js
jobs: bundle exec rake sneakers:run
resque: bundle exec rake resque:work INTERVAL=1 QUEUE="trader_production_trader" FORK_PER_JOB=false
paymium_public_node: nodejs node/paymium_public.js
resque_refresh: bundle exec rake resque:work INTERVAL=1 QUEUE="trader_production_refresh_data"
resque_scheduler: bundle exec rake resque:scheduler