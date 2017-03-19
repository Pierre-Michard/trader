class EventsWorker
  include Sneakers::Worker
  from_queue 'paymium', env: nil

  def work(raw_event)
    #event_params = JSON.parse(raw_event)
    worker_trace("working on it!")
    worker_trace(raw_event)
    RecentPaymiumUserMessages.push(raw_event)
    ack!
  end
end