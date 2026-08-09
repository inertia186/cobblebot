class Admin::SuggestionsController < Admin::AdminController
  SUGGESTIONS = {
    'callbacks' => %w[command cooldown help_doc_key help_doc main pattern type],
    'donations' => %w[main],
    'ips' => %w[main],
    'links' => %w[main],
    'messages' => %w[main],
    'players' => %w[main],
    'server_properties' => %w[
      announce_player_achievements enable_query enable_rcon online_mode
      resource_pack_hash resource_pack_sha1 resource_pack
    ]
  }.each_value(&:freeze).freeze

  before_action :authenticate_admin!

  def show
    @group = params[:group]
    @key = params[:key]
    @verbose = params[:verbose]

    return head :not_found unless SUGGESTIONS.fetch(@group, []).include?(@key)

    render "admin/suggestions/#{@group}/#{@key}", layout: nil
  end
end
