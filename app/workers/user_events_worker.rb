class EventsWorker
  include Sneakers::Worker
  from_queue 'paymium_events', env: nil

  def work(raw_event)
    if raw_event == 'ready'
      PaymiumService.instance.broadcast_channel_id
    else
      RecentPaymiumUserMessages.push(raw_event)
      event = JSON.parse(raw_event).with_indifferent_access
      orders = event[:orders]

      unless orders.blank?
        PaymiumService.instance.extract_trades(from_orders:orders).each do |trade|
          if trade[:created_at] > 10.minutes.ago
            Sneakers::logger.info "trade #{trade[:uuid]}: #{trade[:amount]}"
            Trade.find_or_create_by!(paymium_uuid: trade[:uuid]) do |t|
              t.btc_amount= trade[:amount]
            end
          end
        end
      end
      #Trader.monitor_trades
    end
    ack!
  end
end