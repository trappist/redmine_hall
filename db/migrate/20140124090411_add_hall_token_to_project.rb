class AddHallTokenToProject < ActiveRecord::Migration
  def change
    add_column :projects, :hall_auth_token, :string, :default => "", :null => false
  end
end
