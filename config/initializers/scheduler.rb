require 'rufus-scheduler'

s = Rufus::Scheduler.singleton

if $PROGRAM_NAME.match?('bin/rails') && Rails.const_defined?( 'Server')
  s.every '2s' do
    unless $exiting_rails
      MonitorPriceJob.perform_later unless Resque.size('trader_production_trader') > 2
    end
  end

  s.every '31s' do
    MonitorTradesJob.perform_later unless Resque.size('trader_production_trader') > 2
  end

  s.every '10s' do
    RefreshPaymiumInfo.perform_later
  end

  s.every '30s' do
    RefreshKrakenAccountJob.perform_later unless Resque.size('trader_production_refresh_data') > 2
  end

  s.every '1h' do
    Stat.create!
  end

end