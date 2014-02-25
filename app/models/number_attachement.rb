class NumberAttachement < ActiveRecord::Base
  attr_accessible :phoneable_id, :phoneable_type, :plivo_number_id

  belongs_to :phoneable, polymorphic: true
  belongs_to :plivo_number

end
