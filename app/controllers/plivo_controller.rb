class PlivoController < ApplicationController
  def answer
    #puts params
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
          xml.Record(action: "http://dev.daqe.com/plivo/get_record", maxLength: "30", finishOnKey: "*")
          xml.Speak "Recording not received"
        }
      end
    else
      callerId = params["From"].starts_with?("sip") ? params["X-PH-Phone"] : params["From"]
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.Response {
          #xml.Play "https://s3.amazonaws.com/plivocloud/Trumpet.mp3"
          xml.Speak "Hello! I'm connecting you with one of our managers." unless params["From"].starts_with?("sip")
          xml.Dial(:callerId => callerId) {
            if params["From"].starts_with?("sip")
              xml.Number params["To"]
            else
              xml.User "sip:#{Setting['plivo_endpoint_username']}@phone.plivo.com"
            end
          }
        }
      end
      if params["From"].starts_with?("sip")
        item = Account.by_any_phone(params["To"]) || Contact.by_any_phone(params["To"])
        user = User.find_by_phone(params["X-PH-Phone"])
        event_type = "outbound_call"
      else
        item = Account.by_any_phone(params["From"]) || Contact.by_any_phone(params["From"])
        user = User.find_by_phone(params["To"])
        event_type = "inbound_call"
      end
      if item && user
        Version.create(:whodunnit => user.id.to_s, :event => event_type, :item_id => item.id, :item_type => item.class.model_name)
      end
    end

    render :xml => builder
  end

  def hangup
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

end

