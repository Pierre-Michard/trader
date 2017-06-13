require 'rufus-scheduler'

s = Rufus::Scheduler.singleton

if $PROGRAM_NAME.match?('bin/rails') && Rails.const_defined?( 'Server')
  s.every '10s' do
    unless $exiting_rails
      MonitorPriceJob.perform_later
    end
  end

  #s.every '9s' do
  #  unless $exiting_rails
  #    MonitorTradesJob.perform_later
  #  end
  #end
end