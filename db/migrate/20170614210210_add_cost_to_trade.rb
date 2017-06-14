class AddCostToTrade < ActiveRecord::Migration[5.0]
  def change
    add_column :trades, :kraken_cost, :float
    add_column :trades, :paymium_cost, :float
    add_column :trades, :paymium_price, :float
  end
end
