class VoiceMail < ActiveRecord::Base
  belongs_to :plivo_number
  attr_accessible :from, :record_url
end
