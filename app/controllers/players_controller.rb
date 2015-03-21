class PlayersController < ApplicationController
  def index
    @nicks = []
    
    unless ServerQuery.numplayers == '0'
      result = ServerCommand.execute 'list'
      
      nicks = result.split(':')[1]

      @nicks += nicks.split(", ")
    end
  end
end
