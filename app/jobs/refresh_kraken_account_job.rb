class RefreshKrakenAccountJob < ApplicationJob
  queue_as :refresh_data
  include ActiveJob::Retriable

  def perform
    KrakenService.instance.update_cache
  end
end