class RenameKrakenToCounterOrdersService < ActiveRecord::Migration[5.0]
  def change
    rename_column :trades, :kraken_price, :counter_order_price
    rename_column :trades, :kraken_uuid, :counter_order_uuid
    rename_column :trades, :kraken_fee, :counter_order_fee
    rename_column :trades, :kraken_cost, :counter_order_cost
  end
end
