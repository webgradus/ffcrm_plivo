Rails.application.routes.draw do
    post "/plivo/answer" => "plivo#answer"
    post "/plivo/hangup" => "plivo#hangup"
    post "/plivo/message" => "plivo#message"
    resources :messages, only: :create
end
