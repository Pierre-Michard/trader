class AddPaymiumOrderUuidToTrade < ActiveRecord::Migration[5.0]
  def change
    add_column :trades, :paymium_order_uuid, :string
  end
end
