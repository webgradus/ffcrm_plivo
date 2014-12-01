Account.class_eval do
  has_many :calls, as: :from
    def self.by_any_phone(phone)
        find_by_phone(phone) ||
        find_by_toll_free_phone(phone) ||
        find_by_fax(phone)
    end
end
