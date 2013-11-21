require 'plivo'
class MessagesController < ApplicationController
    before_filter :require_user

    def create
        api = Plivo::RestAPI.new(Setting['plivo_auth_id'], Setting['plivo_auth_token'])

        # Send SMS
        plivo_params = {'src' => current_user.phone,
                  'dst' => params[:recipient],
                  'text' => params[:message],
                  'type' => 'sms',
        }
        response = api.send_message(plivo_params)
    end

end
