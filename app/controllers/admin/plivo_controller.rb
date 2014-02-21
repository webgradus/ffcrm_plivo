class Admin::PlivoController < Admin::ApplicationController
  unloadable
  before_filter :set_current_tab
  before_filter "set_current_tab('admin/plivo')"
  def index

    @plivo_numbers = PlivoNumber.all
    #TODO check numbers. maybe delete from plivo admin
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
    @users = User.all - User.joins(:plivo_number)
    @group = Group.all - Group.joins(:plivo_number)
  end
  def create
    debugger
    p = Plivo::RestAPI.new(Setting['plivo_auth_id'], Setting['plivo_auth_token'])
    #resp = p.rent_from_number_group('group_id' => params[:group_id], 'app_id' => Setting['plivo_app_id'])

    #For debug
    resp=[201,{"numbers" => [{"number" => 123}]}]

    if resp.first == 201
      number = resp.second["numbers"].first["number"]
      params[:plivo_number][:number] = number
      @plivo_number = PlivoNumber.create(params[:plivo_number])
      redirect_to edit_admin_plivo_path(@plivo_number)
    else
      redirect_to destination_admin_plivo_index_path(group_id: params[:group_id]), flash: {error: 'Something went wrong!'}
    end
  end
  def edit
    @plivo_number = PlivoNumber.find_by_id(params[:id])
  end
  def update
    @plivo_number = PlivoNumber.find_by_id(params[:id])
    @plivo_number.update_attributes(params[:plivo_number])
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
