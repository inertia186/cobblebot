class IrcController < ApplicationController
  def index
    @active_in_irc = Preference.active_in_irc.to_i
  end
end
