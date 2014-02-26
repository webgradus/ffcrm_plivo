Rails.application.routes.draw do
    post "/plivo/answer" => "plivo#answer"
    post "/plivo/hangup" => "plivo#hangup"
    post "/plivo/message" => "plivo#message"
    post "/plivo/get_record" => "plivo#get_record"
    resources :messages, only: :create
    namespace :admin do
      resources :plivo, except: :show do
        collection do
          post 'search'
          get 'choose_destination', as: 'destination'
          get 'check_actual_numbers'
        end
      end
    end
end
