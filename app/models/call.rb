class Call < ActiveRecord::Base
  attr_accessible :event, :from_id, :from_type, :uuid, :to
  attr_accessible :start_time, :answer_time, :end_time, :duration
  belongs_to :from, polymorphic: true
  has_one :voice_mail
end
