class RefreshPaymiumInfo < ApplicationJob
  queue_as :refresh_data

  def perform
    PaymiumService.instance.sdepth(force: true)
    PaymiumService.instance.update_cache
  end
end
