class UserEventsWorker
  include Sneakers::Worker
  from_queue 'paymium_events', env: nil

  def work(raw_event)
    Sneakers::logger.info "recevied raw_event #{raw_event}"
    if raw_event == 'ready'
      PaymiumService.instance.broadcast_channel_id
    else
      event = JSON.parse(raw_event).with_indifferent_access
      orders = event[:orders]

      unless orders.blank?
        PaymiumService.instance.extract_trades(from_orders:orders).each do |trade|
          if trade[:created_at] > 1.minute.ago
            Sneakers::logger.info "trade #{trade[:uuid]}: #{trade[:amount]}"
            Rails.cache.delete(:current_orders)
            MonitorTradesJob.perform
          end
        end
      end
      PaymiumService.instance.update_user(event)
    end
    ack!
  end
end