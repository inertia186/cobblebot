class DonationsController < ApplicationController
  respond_to :json

  def index
    @donations = Message::Donation.order('messages.created_at DESC')
    @donations = @donations.preload(:author)
    
    respond_to do |format|
      format.html
      format.json { respond_with @donations }
    end
  end
end
