class VoicemailsController < ApplicationController
  before_filter :set_current_tab, :only => :index
  before_filter :require_user
  def index
    @voicemails = VoiceMail.all
  end
  def destroy
    @voicemail = VoiceMail.find_by_id(params[:id])
    p = Plivo::RestAPI.new(Setting['plivo_auth_id'], Setting['plivo_auth_token'])
    resp = p.delete_recording('recording_id' => @voicemail.record_id)
    if resp.first == 204
      @voicemail.destroy
      render :index
    else
      redirect_to voicemails_path, flash: { error: "Problem with connection to Plivo Service" }
    end

  end
end
