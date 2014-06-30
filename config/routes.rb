Rails.application.routes.draw do
    post "/plivo/answer" => "plivo#answer"
    post "/plivo/hangup" => "plivo#hangup"
    post "/plivo/message" => "plivo#message"
    post "/plivo/get_record" => "plivo#get_record"
    post "/plivo/answer" => "plivo#answer"
    post "/plivo/call" => "plivo#call"
    get "/plivo/phone" => "plivo#phone"
    post "/plivo/phone/conference" => "plivo#conference"
    post "/plivo/phone/answer_conf" => "plivo#answer_conf"
    post "/plivo/phone/send" => "plivo#send_phone"
    post "/plivo/phone/music" => "plivo#music"
    post "/users/online" => "users#online"
    resources :messages, only: :create
    resources :voicemails
    namespace :admin do
      resources :plivo, except: :show do
        collection do
          post 'search'
          get 'choose_destination', as: 'destination'
          get 'check_actual_numbers'
        end
      end
      get '/plivo_number/field_group' => "plivo#field_group"
    end


end
