Resque::Server.set :environment, Rails.env.to_sym

Resque::Server.use(Rack::Auth::Basic) do |_user, password|
  password == Preference.web_admin_password
end