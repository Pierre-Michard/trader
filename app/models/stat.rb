class Stat < ApplicationRecord

  after_initialize do
    self[:price] ||= KrakenService.instance.last_trade['price']
    self[:paymium_btc_balance]  ||= PaymiumService.instance.balance_btc + PaymiumService.instance.locked_btc
    self[:paymium_eur_balance]  ||= PaymiumService.instance.balance_eur + PaymiumService.instance.locked_eur
    #self[:kraken_eur_balance]   ||= KrakenService.instance.balance_eur
    self[:kraken_eur_balance]   ||= 48.02
    #self[:kraken_btc_balance]   ||= KrakenService.instance.balance_btc
    self[:kraken_btc_balance] ||= 0.06644202
    self[:gdax_eur_balance]   ||= GdaxService.instance.balance_eur
    self[:gdax_btc_balance]   ||= GdaxService.instance.balance_btc
    self[:paymium_best_bid]     ||= PaymiumService.instance.bids[0][:price]
    self[:paymium_best_ask]     ||= PaymiumService.instance.asks[0][:price]
    self[:kraken_best_bid]      ||= KrakenService.instance.bids[0][:price]
    self[:kraken_best_ask]      ||= KrakenService.instance.asks[0][:price]
    self[:gdax_best_bid]      ||= GdaxService.instance.bids[0][:price]
    self[:gdax_best_ask]      ||= GdaxService.instance.asks[0][:price]
  end

  def total_paymium_virtual_btc
    paymium_btc_balance  + (paymium_eur_balance)/price
  end

  def total_paymium_virtual_eur
    paymium_eur_balance  + (paymium_btc_balance)*price
  end

  def total_kraken_virtual_btc
    kraken_btc_balance  + (kraken_eur_balance)/price
  end

  def total_kraken_virtual_eur
    kraken_eur_balance  + (kraken_btc_balance)*price
  end

  def total_gdax_virtual_btc
    gdax_btc_balance  + (gdax_eur_balance)/price
  end

  def total_gdax_virtual_eur
    gdax_eur_balance  + (gdax_btc_balance)*price
  end

  def total_virtual_btc
    total_kraken_virtual_btc + total_paymium_virtual_btc + total_gdax_virtual_btc
  end

  def total_virtual_eur
    total_kraken_virtual_eur + total_paymium_virtual_eur + total_gdax_virtual_eur
  end

  def total_btc
    kraken_btc_balance + paymium_btc_balance + gdax_btc_balance
  end

  def total_eur
    kraken_eur_balance + paymium_eur_balance + gdax_eur_balance
  end

  def counterpart_best_bid
    send("#{Setting.reference_service}_best_bid")
  end

  def counterpart_best_ask
    send("#{Setting.reference_service}_best_bid")
  end

  def actual_sell_marge
    ((paymium_best_ask - counterpart_best_bid)/price)*100
  end

  def actual_buy_marge
    ((counterpart_best_ask - paymium_best_bid)/price)*100
  end


end
