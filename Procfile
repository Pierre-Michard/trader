web: bundle exec rails server -p $PORT
paymium_private_node: node node/paymium_private.js
kraken_public_node: node node/kraken_public.js
jobs: bundle exec rake sneakers:run
resque: bundle exec rake resque:work INTERVAL=0.1 QUEUE="*" FORK_PER_JOB=false
