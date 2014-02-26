class Admin::PlivoController < Admin::ApplicationController
  unloadable
  before_filter :set_current_tab
  before_filter "set_current_tab('admin/plivo')"
  def index

    @plivo_numbers = PlivoNumber.all
    #TODO check numbers. maybe delete from plivo admin
    #exist special button on index page
  end
  def new
  end
  def search
    p = Plivo::RestAPI.new(Setting['plivo_auth_id'], Setting['plivo_auth_token'])
    unless params[:search][:services]
      params[:search][:services] = 'voice'
    end

    if params[:search][:area_code] and params[:search][:area_code].match(/[0-9]+$/) and params[:search][:area_code].length <= 5
      params[:search][:prefix] = params[:search][:area_code]
    else
      params[:search][:region] = params[:search][:area_code]
    end

    params[:search].except! :area_code
    @resp = p.get_number_group(params[:search])
    if @resp.first == 200
      @groups = @resp.second["objects"]
    end

  end
  def choose_destination
  end
  def create
    p = Plivo::RestAPI.new(Setting['plivo_auth_id'], Setting['plivo_auth_token'])
    resp = p.rent_from_number_group('group_id' => params[:group_id], 'app_id' => Setting['plivo_app_id'])

    #For debug
    #resp=[201,{"numbers" => [{"number" => 123}]}]

    if resp.first == 201
      number = resp.second["numbers"].first["number"]
      params[:plivo_number][:number] = number



      @plivo_number = PlivoNumber.create(params[:plivo_number])

      (params[:group_ids] || []).each do |group_id|
        group = Group.find_by_id(group_id)
        group.plivo_numbers << @plivo_number if group
      end


      (params[:user_ids] || []).each do |user_id|
        user = User.find_by_id(user_id)
        user.plivo_numbers << @plivo_number if user
      end

      redirect_to edit_admin_plivo_path(@plivo_number)
    else
      redirect_to destination_admin_plivo_index_path(group_id: params[:group_id]), flash: {error: 'Something went wrong!'}
    end
  end
  def edit
    @plivo_number = PlivoNumber.find_by_id(params[:id])
    @users = @plivo_number.number_attachements.select {|na|  na.phoneable_type == "User"}.map {|p| p.phoneable_id}
    @groups = @plivo_number.number_attachements.select {|na|  na.phoneable_type == "Group"}.map {|p| p.phoneable_id}
  end
  def update
    @plivo_number = PlivoNumber.find_by_id(params[:id])
    @plivo_number.update_attributes(params[:plivo_number])

    (params[:group_ids] || []).each do |group_id|
      group = Group.find_by_id(group_id)
      group.plivo_numbers << @plivo_number if group and not group.plivo_numbers.include?(@plivo_number)
    end
    @plivo_number.groups.each do |group|
      unless (params[:group_ids] || []).include?(group.id.to_s)
        group.number_attachements.where(plivo_number_id: @plivo_number.id).first.destroy
      end
    end


    (params[:user_ids] || []).each do |user_id|
      user = User.find_by_id(user_id)
      user.plivo_numbers << @plivo_number if user and not user.plivo_numbers.include?(@plivo_number)
    end
    @plivo_number.users.each do |user|
      unless (params[:user_ids] || []).include?(user.id.to_s)
        user.number_attachements.where(plivo_number_id: @plivo_number.id).first.destroy
      end
    end
  end

  def destroy
    @plivo_number = PlivoNumber.find_by_id(params[:id])

    p = Plivo::RestAPI.new(Setting['plivo_auth_id'], Setting['plivo_auth_token'])
    resp = p.unrent_number('number' => @plivo_number.number)
    if resp.first == 204
      @plivo_number.destroy
      redirect_to admin_plivo_index_path
    else
      redirect_to admin_plivo_index_path, flash: {error: 'Something went wrong!'}
    end
  end
  def check_actual_numbers
    @numbers = PlivoNumber.all
    p = Plivo::RestAPI.new(Setting['plivo_auth_id'], Setting['plivo_auth_token'])
    count = 0
    @numbers.each do |number|
      resp = p.get_number("number" => number.number)
      unless resp.first == 200
        number.destroy
        count = count + 1
      end
    end
    redirect_to admin_plivo_index_path, flash: {notice: "#{count} numbers were deleted!"}
  end

end
