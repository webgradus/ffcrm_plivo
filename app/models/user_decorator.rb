User.class_eval do
  has_many :number_attachements, as: :phoneable, uniq: true
  has_many :plivo_numbers, through: :number_attachements, uniq: true

  def available?
    self.online? and not $redis.get(self.id)
  end

  def numbers
    (self.plivo_numbers + self.groups.inject([]) {|s,e| s + e.plivo_numbers }).uniq
  end
end
