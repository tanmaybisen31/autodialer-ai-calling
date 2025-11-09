class Call < ApplicationRecord
  belongs_to :phone_number

  validates :status, inclusion: {
    in: %w[queued ringing in-progress completed busy failed no-answer canceled]
  }

  scope :successful, -> { where(status: 'completed') }
  scope :failed, -> { where(status: ['failed', 'busy', 'no-answer']) }
  scope :active, -> { where(status: ['queued', 'ringing', 'in-progress']) }
  scope :recent, -> { order(created_at: :desc) }

  def update_from_twilio_callback(params)
    update(
      status: params['CallStatus'],
      duration: params['CallDuration']&.to_i,
      started_at: started_at || Time.current,
      ended_at: params['CallStatus'].in?(['completed', 'failed', 'busy', 'no-answer', 'canceled']) ? Time.current : nil
    )

    if status.in?(['completed', 'failed', 'busy', 'no-answer'])
      phone_number.update(status: status == 'completed' ? 'completed' : 'failed')
    end
  end

  def status_label
    case status
    when 'queued' then 'Queued'
    when 'ringing' then 'Ringing'
    when 'in-progress' then 'In Progress'
    when 'completed' then 'Answered'
    when 'busy' then 'Busy'
    when 'failed' then 'Failed'
    when 'no-answer' then 'No Answer'
    when 'canceled' then 'Canceled'
    else status.titleize
    end
  end

  def status_color
    case status
    when 'completed' then 'success'
    when 'in-progress', 'ringing' then 'primary'
    when 'queued' then 'info'
    when 'busy', 'no-answer' then 'warning'
    when 'failed', 'canceled' then 'danger'
    else 'secondary'
    end
  end
end
