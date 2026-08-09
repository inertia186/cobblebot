class DonationsController < ApplicationController
  respond_to :html, :json, :atom

  def index
    @donations = Message::Donation.order('messages.created_at DESC')
    @donations = @donations.preload(:author)
    
    respond_to do |format|
      format.html
      format.json { respond_with @donations }
      format.atom
    end
  end
end
