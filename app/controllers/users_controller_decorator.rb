UsersController.class_eval do
  def online
    users = SessionTracker.new("user").active_users_data(5, Time.now)
    respond_to do |format|
      format.json { render :json => users }
    end
  end
end
