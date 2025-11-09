Rails.application.routes.draw do
  root 'dialer#index'

  resources :phone_numbers, only: [:index, :create, :destroy] do
    collection do
      post :bulk_upload
      post :generate_test_numbers
    end
  end

  resources :calls, only: [:index, :show] do
    collection do
      post :start_autodialer
      post :stop_autodialer
      post :ai_command
    end
    member do
      get :status
    end
  end

  post '/twilio/voice', to: 'twilio#voice'
  post '/twilio/status', to: 'twilio#status'
  get '/twilio/gather', to: 'twilio#gather'

  post '/ai/synthesize', to: 'ai#synthesize'

  get '/dashboard', to: 'dialer#dashboard'

  resources :blogs, only: [:index, :show] do
    collection do
      get :ask  # RAG Q&A interface
      post :answer  # Process RAG question
      get :search  # Semantic search
      get :generate  # Show bulk generation form
      post :bulk_generate  # Process bulk generation
    end
  end
end
