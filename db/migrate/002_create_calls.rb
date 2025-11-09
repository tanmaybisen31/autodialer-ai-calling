class CreateCalls < ActiveRecord::Migration[7.0]
  def change
    create_table :calls do |t|
      t.references :phone_number, null: false, foreign_key: true
      t.string :twilio_call_sid
      t.string :status # queued, ringing, in-progress, completed, busy, failed, no-answer, canceled
      t.string :direction, default: 'outbound-api'
      t.integer :duration # in seconds
      t.datetime :started_at
      t.datetime :ended_at
      t.text :error_message
      t.string :call_type, default: 'autodialer' # autodialer, manual, ai_command
      t.text :ai_transcript
      t.json :metadata

      t.timestamps
    end

    add_index :calls, :twilio_call_sid, unique: true
    add_index :calls, :status
    add_index :calls, :created_at
  end
end
