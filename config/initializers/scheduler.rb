require 'rufus-scheduler'

s = Rufus::Scheduler.singleton

if $PROGRAM_NAME.match?('bin/rails') && Rails.const_defined?( 'Server')
  s.every '10s' do
    unless $exiting_rails
      MonitorPriceJob.perform_later unless Resque.size('trader_production_trader') > 1
    end
  end

  s.every '30s' do
    RefreshPaymiumPublicInfo.perform_later
  end

  s.every '30s' do
    RefreshKrakenAccountJob.perform_later
  end

end