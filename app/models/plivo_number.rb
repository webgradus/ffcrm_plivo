class PlivoNumber < ActiveRecord::Base
  attr_accessible :number, :label, :start_time, :end_time, :business_time_zone
  has_many :number_attachements, uniq: true
  has_many :voice_mails
  def users
    User.joins(:plivo_numbers).where("plivo_number_id = ?", self.id).uniq
  end
  def groups
    Group.joins(:plivo_numbers).where("plivo_number_id = ?", self.id).uniq
  end

  def business_time?
    time_now = Time.use_zone(self.business_time_zone){Time.now}.localtime.change(day: 1, month: 1, year: 2000)
    start_time = Time.use_zone(self.business_time_zone){Time.zone.local_to_utc(self.start_time)}.localtime
    end_time = Time.use_zone(self.business_time_zone){Time.zone.local_to_utc(self.end_time)}.localtime
    if  start_time < time_now and time_now < end_time
      true
    else
      false
    end
  end

end
