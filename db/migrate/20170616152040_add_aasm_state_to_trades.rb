class AddAasmStateToTrades < ActiveRecord::Migration
  def change
    add_column :trades, :aasm_state, :string
  end
end
