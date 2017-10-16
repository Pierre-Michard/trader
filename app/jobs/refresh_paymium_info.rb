class RefreshPaymiumInfo < ApplicationJob
  queue_as :refresh_data

  def perform
    Stat.create!
    PaymiumService.instance.sdepth(force: true)
    PaymiumService.instance.update_cache
  end
end
