class GdaxPublicWorker
  include Sneakers::Worker
  from_queue 'gdax_public', env: nil

  def work(raw_event)
    event = JSON.parse(raw_event).with_indifferent_access
    case event[:type]
    when 'trades'
      event[:trades].each do |trade|
        GdaxService.instance.push_trade(trade.to_json)
      end
    when 'sdepth'
      GdaxService.instance.set_sdepth(event.to_json)

    else
      Sneakers::logger.warn "unknown event type #{event[:type]}"
    end
    ack!
  end
end
