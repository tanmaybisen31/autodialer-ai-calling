class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token, if: :twilio_request?

  private

  def twilio_request?
    request.path.start_with?('/twilio')
  end
end
