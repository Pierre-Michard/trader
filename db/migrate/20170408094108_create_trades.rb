class CreateTrades < ActiveRecord::Migration[5.0]
  def change
    create_table :trades do |t|
      t.string :paymium_uuid
      t.string :kraken_uuid
      t.float :btc_amount
      t.float :eur_amount

      t.timestamps
    end
  end
end
