class SuggestionsController < ApplicationController
  SUGGESTIONS = {
    'donations' => %w[main],
    'pvps' => %w[main],
    'topics' => %w[main]
  }.each_value(&:freeze).freeze

  def show
    @group = params[:group]
    @key = params[:key]
    @verbose = params[:verbose]
    return head :not_found unless SUGGESTIONS.fetch(@group, []).include?(@key)

    render "suggestions/#{@group.underscore}/#{@key.underscore}", layout: nil
  end
end
