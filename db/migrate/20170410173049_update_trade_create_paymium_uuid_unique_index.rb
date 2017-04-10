class UpdateTradeCreatePaymiumUuidUniqueIndex < ActiveRecord::Migration[5.0]
  def change
    add_index :trades, :paymium_uuid, unique: true
  end
end
