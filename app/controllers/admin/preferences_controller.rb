class Admin::PreferencesController < Admin::AdminController
  before_filter :authenticate_admin!

  def index
    @preferences = Preference.find_or_create_all(false)
  end
  
  def edit
    @preference = Preference.find_or_create_by(key: params[:id])
  end
  
  def update
    key = params[:id]
    @preference = Preference.find_or_create_by(key: key)

    if key =~ /_json$/
      val = params[:preference][:value]
      line_no = 0
      begin
        val.each_line do |line|
          line_no = line_no + 1
          json = JSON.parse(line)
        end
      rescue JSON::ParserError => e
        @preference.value = val
        @preference.errors[:value] << "Problem on line #{line_no}: #{e.message.split(': ').last}"
        
        render 'edit' and return
      end
    end

    if @preference.update_attributes(preference_params)
      ServerProperties.reset_vars
      ServerCommand.reset_vars
      redirect_to admin_preferences_url
    end
  end
private
  def preference_params
    attributes = [:value]

    params.require(:preference).permit *attributes
  end
end