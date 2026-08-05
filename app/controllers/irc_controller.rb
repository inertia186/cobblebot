class IrcController < ApplicationController
  protect_from_forgery except: :index

  def index
    @active_in_irc = Preference.active_in_irc.to_i
  end
end
