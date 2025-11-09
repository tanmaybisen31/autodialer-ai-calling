class PhoneNumbersController < ApplicationController
  def index
    @phone_numbers = PhoneNumber.order(created_at: :desc)
    render json: @phone_numbers
  end

  def create
    @phone_number = PhoneNumber.new(phone_number_params)

    if @phone_number.save
      render json: { success: true, phone_number: @phone_number }
    else
      render json: { success: false, errors: @phone_number.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @phone_number = PhoneNumber.find(params[:id])
    @phone_number.destroy
    render json: { success: true }
  end

  def bulk_upload
    numbers_text = params[:numbers]
    numbers_array = numbers_text.split(/[\n,]/).map(&:strip).reject(&:blank?)

    created = []
    errors = []

    numbers_array.each do |number|
      cleaned_number = number.gsub(/[\s\-\(\)]/, '')

      phone_number = PhoneNumber.new(
        number: cleaned_number,
        country_code: '+91',
        is_test_number: false
      )

      if phone_number.save
        created << phone_number
      else
        errors << { number: number, errors: phone_number.errors.full_messages }
      end
    end

    render json: {
      success: true,
      created: created.count,
      errors: errors,
      phone_numbers: created
    }
  end

  def generate_test_numbers
    count = (params[:count] || 100).to_i
    created = []

    real_numbers = [
      { number: '9999999999', name: 'Test Contact 1', is_test_number: false },
      { number: '8888888888', name: 'Test Contact 2', is_test_number: false }
    ]

    real_numbers.each do |num_data|
      phone_number = PhoneNumber.find_or_create_by(number: num_data[:number]) do |pn|
        pn.country_code = '+91'
        pn.name = num_data[:name]
        pn.is_test_number = num_data[:is_test_number]
      end
      created << phone_number if phone_number.persisted?
    end

    remaining = count - created.count
    remaining.times do |i|
      random_number = "1800#{rand(100..999)}#{rand(1000..9999)}"

      phone_number = PhoneNumber.find_or_create_by(number: random_number) do |pn|
        pn.country_code = '+91'
        pn.name = "Test Number #{i + 1}"
        pn.is_test_number = true
      end

      created << phone_number if phone_number.persisted?
    end

    render json: {
      success: true,
      created: created.count,
      phone_numbers: created
    }
  end

  private

  def phone_number_params
    params.require(:phone_number).permit(:number, :country_code, :name, :is_test_number)
  end
end
