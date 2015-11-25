class StatusController < ApplicationController
  respond_to :json
  
  def index
    @query = ServerQuery.full_query
    @query = @query.merge(params)
    
    @query = @query.map do |q|
      if q[1].class == Time
        {q[0] => q[1].to_i}
      elsif q[1].class == String
        {q[0] => q[1].unpack("C*").pack("U*")}
      else
        {q[0] => q[1]}
      end
    end.reduce(Hash.new, :merge)
    
    respond_to do |format|
      format.html { }
      format.json { }
    end
  end
end
