class Stat < ApplicationRecord

  after_initialize do
    self[:price] ||= KrakenService.instance.last_trade['price']
    self[:paymium_btc_balance]  ||= PaymiumService.instance.balance_btc + PaymiumService.instance.locked_btc
    self[:paymium_eur_balance]  ||= PaymiumService.instance.balance_eur + PaymiumService.instance.locked_eur
    self[:kraken_eur_balance]   ||= KrakenService.instance.balance_eur
    self[:kraken_btc_balance]   ||= KrakenService.instance.balance_btc
    self[:paymium_best_bid]     ||= PaymiumService.instance.bids[0][:price]
    self[:paymium_best_ask]     ||= PaymiumService.instance.asks[0][:price]
    self[:kraken_best_bid]      ||= KrakenService.instance.bids[0][:price]
    self[:kraken_best_ask]      ||= KrakenService.instance.asks[0][:price]
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

  def total_virtual_btc
    total_kraken_virtual_btc + total_paymium_virtual_btc
  end

  def total_virtual_eur
    total_kraken_virtual_eur + total_paymium_virtual_eur
  end

  def total_btc
    kraken_btc_balance + paymium_btc_balance
  end

  def total_eur
    kraken_eur_balance + paymium_eur_balance
  end

end
