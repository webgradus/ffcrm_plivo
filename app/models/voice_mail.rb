class VoiceMail < ActiveRecord::Base
  belongs_to :plivo_number
  attr_accessible :from, :record_url, :record_id
  default_scope order('created_at DESC')
end
