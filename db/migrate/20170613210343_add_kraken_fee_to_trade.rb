class AddKrakenFeeToTrade < ActiveRecord::Migration[5.0]
  def change
    add_column :trades, :kraken_fee, :float
  end
end
