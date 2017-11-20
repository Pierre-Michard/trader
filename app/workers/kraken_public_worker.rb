class KrakenPublicWorker
  include Sneakers::Worker
  from_queue 'kraken_public', env: nil

  def work(raw_event)
    event = JSON.parse(raw_event).with_indifferent_access
    case event[:type]
    when 'trades'
      event[:trades].each do |trade|
        KrakenTradesService.push(trade.to_json)
        #Sneakers::logger.info "received trade #{KrakenTradesService.list.last}"
      end
    when 'sdepth'
      KrakenSdepthService.set(event.to_json)
      #Sneakers::logger.info "#{event[:sdepth][:now]}: received sdepth #{KrakenSdepthService.get}"

    else
      Sneakers::logger.warn "unknown event type #{event[:type]}"
    end
    ack!
  end
end
