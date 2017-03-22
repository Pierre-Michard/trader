class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :paymium_secret
      t.string :paymium_token
      t.string :kraken_secret
      t.string :kraken_token

      t.timestamps
    end
  end
end
