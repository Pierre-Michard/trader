class EventsWorker
  include Sneakers::Worker
  from_queue 'paymium_events', env: nil

  def work(raw_event)
    if raw_event == 'ready'
      PaymiumService.instance.broadcast_channel_id
    else
      event_params = JSON.parse(raw_event)
      worker_trace("working on it!")
      worker_trace(raw_event)
      RecentPaymiumUserMessages.push(raw_event)
    end
    ack!
  end
end