Group.class_eval do
  has_many :number_attachements, as: :phoneable, uniq: true
  has_many :plivo_numbers, through: :number_attachements, uniq: true

  def full_name
    self.name
  end
end
