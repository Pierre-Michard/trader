class AddKrakenPriceToTrade < ActiveRecord::Migration[5.0]
  def change
    add_column :trades, :kraken_price, :float
  end
end
