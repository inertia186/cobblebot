Resque::Server.set :environment, Rails.env.to_sym

Resque::Server.use(Rack::Auth::Basic) do |user, password|
  expected_password = Preference.web_admin_password.to_s
  user == 'admin' && password.to_s.bytesize == expected_password.bytesize &&
    ActiveSupport::SecurityUtils.secure_compare(password.to_s, expected_password)
end
