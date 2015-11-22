class StatusController < ApplicationController
  respond_to :json
  
  def index
    query = ServerQuery.full_query
    
    query = query.map do |q|
      if q[1].class == Time
        {q[0] => q[1].to_i}
      else
        {q[0] => q[1]}
      end
    end.reduce(Hash.new, :merge)
    
    @preloadedStatus = query
    
    respond_to do |format|
      format.html { @preloadedStatus }
      format.json { respond_with @preloadedStatus.map { |q| {'key' => q[0], 'value' => q[1]} } }
    end
  end
end
