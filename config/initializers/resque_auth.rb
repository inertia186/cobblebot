Resque::Server.use(Rack::Auth::Basic) do |user, password|
  password == Preference.web_admin_password
end