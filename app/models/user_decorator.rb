User.class_eval do
  has_one :plivo_number, as: :phoneable
end
