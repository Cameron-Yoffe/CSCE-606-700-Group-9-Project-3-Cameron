class ChangeValueToAllowNullInRatings < ActiveRecord::Migration[8.1]
  def change
    change_column_null :ratings, :value, true
  end
end
