Group.class_eval do
  has_one :plivo_number, as: :phoneable
  def full_name
    self.name
  end
end
