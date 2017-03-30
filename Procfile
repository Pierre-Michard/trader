#web: bundle exec rails server -p $PORT
node: node node/ws.js
jobs: bundle exec rake sneakers:run
resque: INTERVAL=3 bundle exec rake $RAILS_ENV QUEUE='*' FORK_PER_JOB=false resque:work
scheduler: bundle exec rake resque:scheduler