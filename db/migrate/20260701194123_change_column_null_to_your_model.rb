class ChangeColumnNullToYourModel < ActiveRecord::Migration[8.1]
  def change
    change_column_null :games, :type, false
  end
end
