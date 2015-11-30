require 'test_helper'

class Admin::DonationsControllerTest < ActionController::TestCase
  def setup
    session[:admin_signed_in] = true
  end

  def test_routings
    assert_routing({ method: 'get', path: 'admin/donations' }, controller: 'admin/donations', action: 'index')
  end

  def test_index
    get :index
    donations = assigns :donations
    refute_equal donations.count(:all), 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
  end

  def test_index_sort_by_donation_given_by
    get :index, sort_field: 'donation_author_nick'
    donations = assigns :donations
    refute_equal donations.count(:all), 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
  end

  def test_index_feed
    basic = ActionController::HttpAuthentication::Basic
    credentials = basic.encode_credentials('admin', Preference.web_admin_password)
    request.headers['Authorization'] = credentials

    skip 'Donations index.atom not implemented.'
    get :index, format: :atom
    donations = assigns :donations
    refute_equal donations.count(:all), 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
  end

  def test_index
    get :index
    donations = assigns :donations
    refute_equal donations.count(:all), 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
  end

  def test_index_for_players
    player = Player.first
    assert_difference -> { player.donations.count }, 1, 'expect different count' do
      Message::Donation.first.update_attribute(:author, player)
    end

    get :index, player_id: player
    donations = assigns :donations
    refute_equal donations.count(:all), 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
  end

  def test_show
    skip 'Donations show.html not implemented.'
    get :show, id: Message::Donation.first

    assert_template :_donation
    assert_template :show
    assert_template 'layouts/application'
    assert_response :success
  end

  def test_new
    get :new
    assert assigns :donation

    assert_template :_form
    assert_template :new
    assert_template 'layouts/application'
    assert_response :success
  end

  def test_edit
    get :edit, id: Message::Donation.first
    assert assigns :donation

    assert_template :_form
    assert_template :edit
    assert_template 'layouts/application'
    assert_response :success
  end

  def test_create
    assert_difference -> { Message::Donation.count }, 1, 'expect different count' do
      post :create, message_donation: donation_params
    end
    assert assigns :donation

    assert_template nil
    assert_redirected_to admin_message_donations_url
  end

  def test_create_failure
    assert_no_difference -> { Message::Donation.count }, 'did not expect different count' do
      post :create, message_donation: donation_params.merge(body: Preference.stop_words)
    end
    assert assigns :donation

    assert_template :_form
    assert_template :new
    assert_template 'layouts/application'
    assert_response :success
  end

  def test_update
    donation = Message::Donation.first
    assert_difference -> { Player.first.donations.count }, 1, 'expect different count' do
      patch :update, id: donation.id, message_donation: donation_params
    end
    assert assigns :donation

    assert_template nil
    assert_redirected_to admin_message_donations_url
  end

  def test_update_failure
    donation = Message::Donation.first
    assert_no_difference -> { Player.first.donations.count }, 'did not expect different count' do
      patch :update, id: donation.id, message_donation: donation_params.merge(body: Preference.stop_words)
    end
    assert assigns :donation

    assert_template :_form
    assert_template :edit
    assert_template 'layouts/application'
    assert_response :success
  end

  def test_destroy
    assert_difference -> { Message::Donation.count }, -1, 'expect different count' do
      delete :destroy, id: Message::Donation.first
    end

    assert_template nil
    assert_redirected_to admin_message_donations_url
  end
private
  def donation_params
    author = Player.first
    {
      author_id: author.id,
      author_type: 'Player',
      body: "$10 from #{author.nick}"
    }
  end
end
