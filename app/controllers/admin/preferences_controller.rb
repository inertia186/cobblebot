class Admin::PreferencesController < Admin::AdminController
  before_action :authenticate_admin!
  after_action :prevent_sensitive_caching

  respond_to :json

  def index
    @preferences = if params[:system] == 'true'
      Preference.system
    else
      Preference.find_or_create_all(false)
    end

    respond_to do |format|
      format.html { }
      format.json { }
    end
  end

  def edit_cell
    render 'edit_cell', layout: nil
  end

  def update
    key = params[:id]
    @preference = Preference.find_or_create_by(key: key)
    attributes = preference_params

    if @preference.secure? && attributes[:value].blank?
      head :accepted and return
    end

    if key =~ /_json$/
      val = attributes[:value]
      line_no = 0
      begin
        val.each_line do |line|
          line_no = line_no + 1
          json = JSON.parse(line)
        end
      rescue JSON::ParserError => e
        @preference.value = val
        @preference.errors.add(:value, "has a problem on line #{line_no}: #{e.message.split(': ').last}")
      end
    elsif key == 'path_to_server'
      unless File.exist? attributes[:value]
        @preference.errors.add(:value, 'does not exist.')
      end
    elsif key == 'irc_server_port'
      val = attributes[:value].to_i
      if val.to_s != attributes[:value]
        @preference.errors.add(:value, 'must be a valid integer.')
      end
      if val < 1 || val > 65535
        @preference.errors.add(:value, 'must be a valid port number (1 to 65535).')
      end
    end

    if @preference.errors.any?
      render json: @preference.errors, status: :unprocessable_entity and return
    end

    if @preference.update(attributes)
      ServerProperties.reset_vars
      ServerCommand.reset_vars

      head 202
    end
  end
private
  def prevent_sensitive_caching
    response.headers['Cache-Control'] = 'no-store'
    response.headers['Pragma'] = 'no-cache'
  end

  def preference_params
    attributes = [:value]

    params.require(:preference).permit *attributes
  end
end
