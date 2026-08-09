class StatusController < ApplicationController
  respond_to :json
  
  def index
    @query = ServerQuery.full_query
    @query = @query.merge(params.permit('angular.version').to_h)
    
    @query = @query.map do |key, value|
      if value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone)
        {key => value.to_i}
      elsif value.is_a?(String)
        {key => value.unpack("C*").pack("U*")}
      else
        {key => value}
      end
    end
    
    respond_to do |format|
      format.html { }
      format.json { }
    end
  end
end
