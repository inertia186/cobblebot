class Admin::PreferencesController < Admin::AdminController
  before_filter :authenticate_admin!

  def index
    @preferences = Preference.find_or_create_all(false)
  end
  
  def edit
    @preference = Preference.find_or_create_by(key: params[:id])
  end
  
  def update
    @preference = Preference.find_or_create_by(key: params[:id])

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