class Admin::SuggestionsController < Admin::AdminController
  def show
    @group = params[:group]
    @key = params[:key]
    @verbose = params[:verbose]
    render "/admin/suggestions/#{@group.underscore}/#{@key.underscore}", layout: nil
  end
end
