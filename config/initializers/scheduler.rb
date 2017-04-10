require 'rufus-scheduler'

s = Rufus::Scheduler.singleton

if $PROGRAM_NAME.match?('bin/rails')
  s.every '10s' do
    UpdateTickerJob.perform_later
    p "hello, it's #{Time.now}"
  end
end