class PlayersController < ApplicationController
  def index
    @players = []
    
    unless query[:numplayers] == '0'
      result = rcon.command 'list'
      
      players = result.split(':')[1]

      @players += players.split(", ")
    end
  end
end
