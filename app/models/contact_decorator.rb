Contact.class_eval do
    def self.by_any_phone(phone)
        find_by_phone(phone) ||
        find_by_mobile(phone) ||
        find_by_fax(phone)
    end
end
