class PlivoController < ApplicationController
  #check_authorization :only => :phone
  #load_and_authorize_resource :only => :phone# handles all security
  def answer
    puts params
    business_time = true
    if not params["From"].starts_with?("sip")
      number = PlivoNumber.find_by_number(params["To"])
      if number and number.business_time?
        business_time = true
      else
        business_time = false
      end
    end
    if not params["From"].starts_with?("sip") and not business_time
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.Response {
          xml.Speak "Please leave a message after the beep. Press the star key when done."
          xml.Record(action: plivo_get_record_url, maxLength: "30", finishOnKey: "*")
          xml.Speak "Recording not received"
        }
      end
    else
      callerId = params["From"].starts_with?("sip") ? params["X-PH-Phone"] : params["From"]
      puts params
      builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml.Response {
          #xml.Play "https://s3.amazonaws.com/plivocloud/Trumpet.mp3"
          xml.Speak "Hello! I'm connecting you with one of our managers." unless params["From"].starts_with?("sip")
          xml.Conference(hangupOnStar: true, stayAlone: false, callbackUrl: plivo_phone_conference_url, waitSound: plivo_phone_music_url, startConferenceOnEnter: params["From"].starts_with?("sip") ? true : false, enterSound: 'beep:1'){
            xml.text params["To"].to_s
          }
          #xml.Speak "Conference Stop"

          #xml.Dial(:callerId => callerId) {
          #  if params["From"].starts_with?("sip")
          #    xml.Number params["To"]
          #  else
          #    xml.User "sip:#{Setting['plivo_endpoint_username']}@phone.plivo.com"
          #  end
          #}
        }
      end
      if params["From"].starts_with?("sip")
        item = Account.by_any_phone(params["To"]) || Contact.by_any_phone(params["To"])
        user = User.find_by_phone(params["X-PH-Phone"])
        event_type = "outbound_call"

        #save status in redis
        user_by_id=User.find_by_id(params["X-PH-User"])
        if user_by_id
          $redis.set(user_by_id.id,params["CallUUID"])
          $redis.set(params["CallUUID"], user_by_id.id)
        end
        #TODO send status message
        Pusher['internal'].trigger('in_call',{
          user_id: params["X-PH-User"]
        })

        if params["X-PH-Outbound"]=="true"
          api = Plivo::RestAPI.new(Setting['plivo_auth_id'],Setting['plivo_auth_token'])
          puts api.make_call("to" => params["To"], "from" => params["X-PH-Phone"], "answer_url" => plivo_phone_answer_conf_url)
          puts params["To"].to_s
        else
          Pusher[params["To"]].trigger('conference_start',{
            conference_name: params["To"].to_s
          })
        end
      else
        item = Account.by_any_phone(params["From"]) || Contact.by_any_phone(params["From"])
        user = User.find_by_phone(params["To"])
        event_type = "inbound_call"

        api = Plivo::RestAPI.new(Setting['plivo_auth_id'],Setting['plivo_auth_token'])
        if api.get_live_conferences()[1]["conferences"].include?(params["To"].to_s)
          #VoiceMail
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.Response {
              xml.Speak "Sorry, but all our managers are busy. Please leave a message after the beep. Press the star key when done."
              xml.Record(action: plivo_get_record_url, maxLength: "30", finishOnKey: "*")
              xml.Speak "Recording not received"
            }
          end
        else
          Pusher[params["To"].to_s].trigger('incoming_conference', {
            conference_name: params["To"].to_s,
            incoming_number: params["From"].to_s
          })
        end
      end
      if item && user
        Version.create(:whodunnit => user.id.to_s, :event => event_type, :item_id => item.id, :item_type => item.class.model_name)
      end
    end

    render :xml => builder
  end

  def hangup

    #make user "free"
    user_id = $redis.get(params["CallUUID"])
    $redis.del(user_id)
    $redis.del(params["CallUUID"])
    #TODO send message
    Pusher["internal"].trigger("free",{
      user_id: user_id
    })
    #puts params
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.Response {
        #xml.Play "https://s3.amazonaws.com/plivocloud/Trumpet.mp3"
        xml.Hangup
      }
    end
    render :xml => builder
  end

  def message
    # Put your logic handling incoming text messages here
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.Response {
        xml.Message
      }
    end
    render :xml => builder
  end

  def get_record
    plivo_number = PlivoNumber.find_by_number(params[:To])
    if plivo_number
      plivo_number.voice_mails.create(from: params["From"], record_url: params["RecordUrl"])
    end
    render nothing: true
  end

  def call
    Pusher['internal'].trigger('call', {
      conference_name: params[:conference].present? ? params[:conference] : current_user.username+'_'+params[:username],
      username: params[:username]
    })
    render nothing: true
  end

  def phone
    render layout: 'phone'
  end

  def conference
    puts params
    if params["ConferenceAction"] == "exit" and params["ConferenceLastMember"] == "true"
      Pusher[params["ConferenceName"]].trigger('conference_end',{
        conference_name: params["ConferenceName"]
      })
    end
    render nothing: true
  end

  def answer_conf
    puts params
    if params["Event"] == "Hangup"
      api = Plivo::RestAPI.new(Setting['plivo_auth_id'],Setting['plivo_auth_token'])
      api.hangup_conference("conference_name" => params["To"])
    else
      builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
          xml.Response {
            #xml.Play "https://s3.amazonaws.com/plivocloud/Trumpet.mp3"
            xml.Speak "Hello! I'm connecting you with one of our managers." unless params["From"].starts_with?("sip")
            xml.Conference(stayAlone: false, callbackUrl: plivo_phone_conference_url, enterSound: 'beep:1', waitSound: plivo_phone_music_url, startConferenceOnEnter: false){
              xml.text params["To"].to_s
            }
          }
      end
      puts params["To"].to_s
    end
    render :xml => builder
  end

  def send_phone
    Pusher['internal'].trigger('send_number',{
      phone_number: params[:phone].gsub(/[\s\+\-()]/,''),
      username: current_user.username
    })
    render nothing: true
  end

  def music
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.Response {
        xml.Play root_url + "wait_sound.mp3"
      }
    end
    render :xml => builder
  end

end

