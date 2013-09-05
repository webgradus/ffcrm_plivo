Rails.application.routes.draw do
    post "/plivo/answer" => "plivo#answer"
    post "/plivo/hangup" => "plivo#hangup"
end
