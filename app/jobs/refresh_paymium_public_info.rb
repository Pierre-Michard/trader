class RefreshPaymiumPublicInfo < ApplicationJob
  queue_as :refresh_data

  def perform
    PaymiumService.instance.sdepth(force: true)
  end
end
