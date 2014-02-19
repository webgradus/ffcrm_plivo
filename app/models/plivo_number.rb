class PlivoNumber < ActiveRecord::Base
  attr_accessible :number, :phoneable_id, :phoneable_type, :label
  belongs_to :phoneable, polymorphic: true
end
