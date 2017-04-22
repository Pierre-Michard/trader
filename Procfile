web: RAILS_ENV=$RAILS_ENV bundle exec rails server -p $PORT
node: node node/ws.js
jobs: RAILS_ENV=$RAILS_ENV bundle exec rake sneakers:run
resque: INTERVAL=3 QUEUE='*' RAILS_ENV=$RAILS_ENV FORK_PER_JOB=false bundle exec rake resque:work
#scheduler: bundle exec rake resque:scheduler