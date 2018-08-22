require 'rufus-scheduler'

s = Rufus::Scheduler.singleton

if $PROGRAM_NAME.match?('bin/rails') && Rails.const_defined?( 'Server')
  s.every '4s' do |job|
    unless $exiting_rails || Setting['active'] == false || Resque.size('trader_production_trader') > 2
      MonitorPriceJob.perform_later

      current_hour = Time.now.hour

      if (0..5).include? current_hour
        job.next_time = EtOrbi::EoTime.now + 10
      elsif (6..7).include? current_hour
        job.next_time = EtOrbi::EoTime.now + 5
      end
    end
  end

  s.every '31s' do
    unless Setting['active'] == false || Resque.size('trader_production_trader') > 2
      MonitorTradesJob.perform_later
    end
  end

  s.every '30s' do
    RefreshPaymiumInfo.perform_later unless Resque.size('trader_production_refresh_data') > 2
  end

  s.every '30s' do
    RefreshKrakenAccountJob.perform_later unless Resque.size('trader_production_refresh_data') > 2
  end


end