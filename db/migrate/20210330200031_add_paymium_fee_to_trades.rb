class AddPaymiumFeeToTrades < ActiveRecord::Migration[5.0]
  def change
    add_column :trades, :paymium_fee, :float
  end
end
