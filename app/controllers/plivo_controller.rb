class PlivoController < ApplicationController
    def answer
        #puts params
        callerId = params["From"].starts_with?("sip") ? params["X-PH-Phone"] : params["From"]
        builder = Nokogiri::XML::Builder.new do |xml|
            xml.Response {
                #xml.Play "https://s3.amazonaws.com/plivocloud/Trumpet.mp3"
                xml.Speak "Hello! I'm connecting you with one of our managers." unless params["From"].starts_with?("sip")
                xml.Dial(:callerId => callerId) {
                    xml.Number params["To"]
                }
            }
        end
        if params["From"].starts_with?("sip")
            item = Account.find_by_phone(params["To"]) || Contact.find_by_phone(params["To"])
            user = User.find_by_phone(params["X-PH-Phone"])
            event_type = "outbound_call"
        else
            item = Account.find_by_phone(params["From"]) || Contact.find_by_phone(params["From"])
            user = User.find_by_phone(params["To"])
            event_type = "inbound_call"
        end
        if item && user
            Version.create(:whodunnit => user.id.to_s, :event => event_type, :item_id => item.id, :item_type => item.class.model_name)
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

end

