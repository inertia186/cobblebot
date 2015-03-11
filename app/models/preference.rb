class Preference < ActiveRecord::Base
  WEB_ADMIN_PASSWORD = 'web_admin_password'
  PATH_TO_SERVER = 'path_to_server'

  ALL_KEYS = [WEB_ADMIN_PASSWORD, PATH_TO_SERVER]

  validates_uniqueness_of :key

  def self.method_missing(m, *args, &block)
    if m.to_s.ends_with?('=') && (ALL_KEYS.include? key = "#{m.to_s.split('=')[0]}")
      return find_or_create_by!(key: key).update_attribute(:value, args[0])
    elsif m.to_s.ends_with?('?') && (ALL_KEYS.include? key = "#{m.to_s.split('?')[0]}")
      return ['true', true, 't'].include? find_or_create_by!(key: key).value
    elsif ALL_KEYS.include? key = m.to_s
      return find_or_create_by!(key: key).value
    end

    super
  end
end
