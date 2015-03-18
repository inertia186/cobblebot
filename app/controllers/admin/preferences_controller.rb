class Admin::PreferencesController < ApplicationController
  before_filter :authenticate_admin!

  def index
    @preferences = Preference.system(false)
  end
  
  def edit
    @preference = Preference.find_by_key(params[:id])
  end
  
  def update
    @preference = Preference.find_by_key(params[:id])

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