class PlivoNumber < ActiveRecord::Base
  attr_accessible :number, :label
  has_many :number_attachements, uniq: true
  has_many :voice_mails
  def users
    User.joins(:plivo_numbers).where("plivo_number_id = ?", self.id).uniq
  end
  def groups
    Group.joins(:plivo_numbers).where("plivo_number_id = ?", self.id).uniq
  end
end
