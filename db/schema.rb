
ActiveRecord::Schema[7.2].define(version: 2) do
  create_table "calls", force: :cascade do |t|
    t.integer "phone_number_id", null: false
    t.string "twilio_call_sid"
    t.string "status"
    t.string "direction", default: "outbound-api"
    t.integer "duration"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.text "error_message"
    t.string "call_type", default: "autodialer"
    t.text "ai_transcript"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_calls_on_created_at"
    t.index ["phone_number_id"], name: "index_calls_on_phone_number_id"
    t.index ["status"], name: "index_calls_on_status"
    t.index ["twilio_call_sid"], name: "index_calls_on_twilio_call_sid", unique: true
  end

  create_table "phone_numbers", force: :cascade do |t|
    t.string "number", null: false
    t.string "country_code", default: "+91"
    t.string "name"
    t.string "status", default: "pending"
    t.boolean "is_test_number", default: false
    t.integer "call_attempts", default: 0
    t.datetime "last_called_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["number"], name: "index_phone_numbers_on_number", unique: true
    t.index ["status"], name: "index_phone_numbers_on_status"
  end

  add_foreign_key "calls", "phone_numbers"
end
