web: bundle exec rails server -p $PORT
paymium_private_node: node node/paymium_private.js
kraken_public_node: node node/kraken_public.js
jobs: bundle exec rake sneakers:run
resque: INTERVAL=3 QUEUE='*' RAILS_ENV=$RAILS_ENV FORK_PER_JOB=false bundle exec rake resque:work
