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
end

