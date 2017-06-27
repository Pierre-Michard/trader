class RefreshKrakenAccountJob < ApplicationJob
  queue_as :refresh_data

  def perform
    KrakenService.instance.update_cache
  end
end