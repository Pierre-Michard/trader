class CreateStats < ActiveRecord::Migration[5.0]
  def change
    create_table :stats do |t|
      t.float :paymium_eur_balance
      t.float :paymium_btc_balance
      t.float :kraken_eur_balance
      t.float :kraken_btc_balance
      t.float :price
      t.float :paymium_best_bid
      t.float :paymium_best_ask
      t.float :kraken_best_bid
      t.float :kraken_best_ask

      t.timestamps
    end
  end
end
