class DialerController < ApplicationController
  def index
    @phone_numbers = PhoneNumber.order(created_at: :desc).limit(100)
    @recent_calls = Call.recent.includes(:phone_number).limit(20)
    @stats = AutodialerService.statistics
  end

  def dashboard
    @stats = AutodialerService.statistics
    @per_page = 25
    @phone_numbers_total = PhoneNumber.count
    @total_pages = [(@phone_numbers_total.to_f / @per_page).ceil, 1].max
    @page = params[:page].to_i
    @page = 1 if @page < 1
    @page = @total_pages if @page > @total_pages

    offset = (@page - 1) * @per_page
    offset = 0 if offset.negative?

    @phone_numbers = PhoneNumber.order(created_at: :desc)
                                .offset(offset)
                                .limit(@per_page)
    @recent_calls = Call.recent.includes(:phone_number).limit(50)

    @calls_by_status = Call.group(:status).count

    @calls_today = Call.where('created_at > ?', 24.hours.ago).count
  end
end
