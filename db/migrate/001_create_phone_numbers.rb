class CreatePhoneNumbers < ActiveRecord::Migration[7.0]
  def change
    create_table :phone_numbers do |t|
      t.string :number, null: false
      t.string :country_code, default: '+91'
      t.string :name
      t.string :status, default: 'pending' # pending, calling, completed, failed
      t.boolean :is_test_number, default: false
      t.integer :call_attempts, default: 0
      t.datetime :last_called_at

      t.timestamps
    end

    add_index :phone_numbers, :number, unique: true
    add_index :phone_numbers, :status
  end
end
