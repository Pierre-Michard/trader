web: bundle exec rails server -p $PORT
node: node node/ws.js
jobs: bundle exec rake sneakers:run
resque: bundle exec rake resque:work INTERVAL=3 QUEUE='*' FORK_PER_JOB=false
