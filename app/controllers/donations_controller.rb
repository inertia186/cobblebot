class DonationsController < ApplicationController
  def index
    @donations = Message::Donation.order('messages.created_at DESC')
    @donations = @donations.paginate(page: params[:page], per_page: 100)
  end
end
