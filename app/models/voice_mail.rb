class VoiceMail < ActiveRecord::Base
  belongs_to :plivo_number
  attr_accessible :from, :record_url, :record_id, :call_id
  belongs_to :call
  default_scope order('created_at DESC')
end
