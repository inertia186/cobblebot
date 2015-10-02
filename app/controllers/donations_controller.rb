class DonationsController < ApplicationController
  def index
    @donations = Message::Donation.order('messages.created_at DESC')
    @donations = @donations.preload(:author)
    @donations = @donations.paginate(page: params[:page], per_page: 100)
  end
end
