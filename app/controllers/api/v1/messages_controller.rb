class Api::V1::MessagesController < Api::V1::ApiController
  def index
    author_id = params[:author_id]
    recipient_id = params[:recipient_id]
    any_recipient_nick = params[:any_recipient_nick]
    filter = params[:filter] || 'deleted,muted' # expect: none, deleted, muted
    limit = params[:limit]
    @messages = Message.where(type: nil)
    
    @messages = @messages.where(author_type: 'Player', author_id: author_id) if author_id.present?
    @messages = @messages.where(recipient_type: 'Player', recipient_id: recipient_id) if recipient_id.present?
    @messages = @messages.where(recipient_type: 'Player', recipient_id: Player.any_nick(any_recipient_nick)) if any_recipient_nick.present?
    @messages = @messages.deleted(false) if filter.include?('deleted')
    @messages = @messages.muted(false) if filter.include?('muted')
    
    @messages = @messages.limit(limit) if limit.present?
  end
  
  def show
    @message = Message.find(params[:id])
  end
end