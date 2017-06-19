class PaymiumPublicWorker
  include Sneakers::Worker
  from_queue 'paymium_public', env: nil

  def work(raw_event)
    event = JSON.parse(raw_event).with_indifferent_access
    Sneakers::logger.info "event: #{event}"
    event.each do |key, value|
      case key
        when 'asks'
          PaymiumService.instance.update_asks(value)
        when 'bids'
          PaymiumService.instance.update_bids(value)
        else
          Sneakers::logger.warn "unknown event type #{key}"
      end
    end
    ack!
  end
end
