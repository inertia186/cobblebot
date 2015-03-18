class PlayersController < ApplicationController
  def index
    @players = []
    
    unless ServerQuery.numplayers == '0'
      result = ServerCommand.execute 'list'
      
      players = result.split(':')[1]

      @players += players.split(", ")
    end
  end
end
