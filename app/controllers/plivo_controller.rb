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

      puts "---------------------"
      puts params["From"].starts_with?("sip") ? params["To"] : params["CallUUID"]
      puts "---------------------"

      builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml.Response {
          #xml.Play "https://s3.amazonaws.com/plivocloud/Trumpet.mp3"
          xml.Speak "Hello! I'm connecting you with one of our managers. If you don't want to wait you can press the star key to leave a message." unless params["From"].starts_with?("sip")
          xml.Conference(hangupOnStar: true, callbackUrl: plivo_phone_conference_url, waitSound: plivo_phone_music_url, startConferenceOnEnter: params["From"].starts_with?("sip") ? true : false, endConferenceOnExit: params["From"].starts_with?("sip") ? false : true){
            xml.text params["From"].starts_with?("sip") ? params["To"].split('@').first.split(':').last : params["CallUUID"]
          }

            xml.Speak "Please leave a message after the beep. Press the star key when done." unless params["From"].starts_with?("sip")
            xml.Record(action: plivo_get_record_url, maxLength: "30", finishOnKey: "*") unless params["From"].starts_with?("sip")
            xml.Speak "Recording not received" unless params["From"].starts_with?("sip")

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

        if params["X-PH-Outbound"] == "true"
          api = Plivo::RestAPI.new(Setting['plivo_auth_id'],Setting['plivo_auth_token'])
          puts api.make_call("to" => params["To"], "from" => params["X-PH-Phone"], "answer_url" => plivo_phone_answer_conf_url)
          puts params["To"].to_s
        else
          if params["To"].starts_with?("sip")
            Pusher['internal'].trigger('conference_start',{
              conference_name: params["To"].split('@').first.split(':').second
            })
          end
        end
      else
        item = Account.by_any_phone(params["From"]) || Contact.by_any_phone(params["From"])
        user = User.find_by_phone(params["To"])
        event_type = "inbound_call"

        #api = Plivo::RestAPI.new(Setting['plivo_auth_id'],Setting['plivo_auth_token'])
        #if api.get_live_conferences()[1]["conferences"].include?(params["To"].to_s)
          #VoiceMail
        #  builder = Nokogiri::XML::Builder.new do |xml|
        #    xml.Response {
        #      xml.Speak "Sorry, but all our managers are busy. Please leave a message after the beep. Press the star key when done."
        #      xml.Record(action: plivo_get_record_url, maxLength: "30", finishOnKey: "*")
        #      xml.Speak "Recording not received"
        #    }
        #  end
        #else
          conf_id = params["CallUUID"]
          Pusher[params["To"].to_s].trigger('incoming_conference', {
            conference_name: conf_id,
            incoming_number: params["From"].to_s

          })

          #Pusher[params["To"].to_s].trigger('incoming_conference', {
          #  conference_name: params["To"].to_s,
          #  incoming_number: params["From"].to_s
          #})
        #end
      end

      if item && user
        if event_type == 'inbound_call'
          call = Call.create(uuid: params['CallUUID'], event: event_type, from_id: item.id, from_type: item.class.model_name, to: params["To"])
        elsif event_type == 'outbound_call'
          call = Call.create(uuid: params['CallUUID'], event: event_type, from_id: user.id, from_type: user.class.model_name, to: params["To"])
        end
        Version.create(:whodunnit => user.id.to_s, :event => event_type, :item_id => item.id, :item_type => item.class.model_name, object: call.nil? ? '' : call.id)

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

    call = Call.find_by_uuid(params['CallUUID'])
    if call and params['action'] == 'hangup'
      call.update_attributes(start_time: params['StartTime'], answer_time: params['AnswerTime'], end_time: params['EndTime'], duration: params['Duration'])
    end

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
    puts params
    plivo_number = PlivoNumber.find_by_number(params[:To])
    call = Call.find_by_uuid(params["CallUUID"])

    if plivo_number
      vm = plivo_number.voice_mails.create(from: params["From"], record_url: params["RecordUrl"], record_id: params["RecordingID"])

      if vm and call
        vm.update_attribute(:call_id, call.id)
      end
    end
    render nothing: true
  end

  def call
    Pusher['internal'].trigger('call', {
      conference_name: params[:conference].present? ? params[:conference] : current_user.username+'_'+params[:username],
      username: params[:username],
      initiator: current_user.full_name
    })
    render nothing: true
  end

  def phone
    render layout: 'phone'
  end

  def conference
    puts params
    if params["ConferenceAction"] == "exit" and params["ConferenceLastMember"] == "true"
      Pusher["internal"].trigger('conference_end',{
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
      render nothing: true
    else
      builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
          xml.Response {
            #xml.Play "https://s3.amazonaws.com/plivocloud/Trumpet.mp3"
            xml.Conference(callbackUrl: plivo_phone_conference_url, enterSound: 'beep:1', waitSound: plivo_phone_music_url, startConferenceOnEnter: false){
              xml.text params["To"].to_s
            }
          }
      end
      puts params["To"].to_s
      render :xml => builder
    end
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

