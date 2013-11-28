class PlivoController < ApplicationController
    def answer
        #puts params
        builder = Nokogiri::XML::Builder.new do |xml|
            xml.Response {
                #xml.Play "https://s3.amazonaws.com/plivocloud/Trumpet.mp3"
                xml.Dial {
                    xml.Number params["To"]
                }
            }
        end
        item = Account.find_by_phone(params["From"]) || Contact.find_by_phone(params["From"])
        user = User.find_by_phone(params["To"])
        if item && user
            Version.create(:whodunnit => user.id.to_s, :event => "inbound_call", :item_id => item.id, :item_type => item.class.model_name)
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

    def audit
        Version.create(params[:version].merge(:whodunnit => PaperTrail.whodunnit))
        render :nothing => true
    end
end

