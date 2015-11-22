class SuggestionsController < ApplicationController
  def show
    @group = params[:group]
    @key = params[:key]
    @verbose = params[:verbose]
    render "suggestions/#{@group.underscore}/#{@key.underscore}", layout: nil
  end
end
