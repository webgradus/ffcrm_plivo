class PlivoNumber < ActiveRecord::Base
  attr_accessible :number, :label, :start_time, :end_time, :business_time_zone, :tag_list
  has_many :number_attachements, uniq: true
  has_many :voice_mails
  acts_as_taggable_on :tags
  has_ransackable_associations %w(tags)
  def users
    User.joins(:plivo_numbers).where("plivo_number_id = ?", self.id).uniq
  end
  def groups
    Group.joins(:plivo_numbers).where("plivo_number_id = ?", self.id).uniq
  end

  def business_time?
    time_now = Time.now.change(day: 1, month: 1, year: 2000)
    offset = ActiveSupport::TimeZone.new(self.business_time_zone).utc_offset()
    start_time = self.start_time - offset
    end_time = self.end_time - offset
    if  start_time < time_now and time_now < end_time
      true
    else
      false
    end
  end

end
