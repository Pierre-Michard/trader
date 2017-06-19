class PaymiumServiceController < ApplicationController
  def sdepth
    @bids = PaymiumService.instance.bids
    @asks = PaymiumService.instance.asks
  end
end
