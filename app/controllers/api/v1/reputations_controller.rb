class Api::V1::ReputationsController < Api::V1::ApiController
  def index
    any_truster_nick = params[:any_truster_nick]
    any_trustee_nick = params[:any_trustee_nick]

    @reputations = Reputation.with_trustables
    @reputations = @reputations.where(truster_id: Player.any_nick(any_truster_nick)) if !!any_truster_nick
    @reputations = @reputations.where(trustee_id: Player.any_nick(any_trustee_nick)) if !!any_trustee_nick
  end
  
  def show
    @reputation = Reputation.find(params[:id])
  end
end