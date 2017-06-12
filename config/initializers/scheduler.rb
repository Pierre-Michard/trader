require 'rufus-scheduler'

s = Rufus::Scheduler.singleton

if $PROGRAM_NAME.match?('bin/rails') && Rails.const_defined?( 'Server')
  s.every '10s' do
    unless $exiting_rails
      MonitorPriceJob.perform_later
      MonitorTradesJob.perform_later
    end
  end
end