class DropUsers < ActiveRecord::Migration[5.0]
  def up
    if ActiveRecord::Base.connection.table_exists? :users
      drop_table :users
    end
  end

  def down

  end
end
