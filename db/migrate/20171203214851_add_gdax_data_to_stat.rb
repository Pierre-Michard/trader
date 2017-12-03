class AddGdaxDataToStat < ActiveRecord::Migration[5.0]
  def change
    add_column :stats, :gdax_eur_balance, :float
    add_column :stats, :gdax_btc_balance, :float
    add_column :stats, :gdax_best_bid, :float
    add_column :stats, :gdax_best_ask, :float
  end
end
