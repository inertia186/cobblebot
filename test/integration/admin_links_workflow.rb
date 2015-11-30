require 'test_helper'

class AdminLinksTest < ActionDispatch::IntegrationTest
  include WebStubs

  VARIATIONS = %w(a b c d e f g)
  STUBS = []

  def setup
    VARIATIONS.each do |s|
      STUBS << stub_request(:get, "http://github.com/inertia186/cobblebot?#{s}=#{s}").
        to_return(status: 200)
    end
  end

  def teardown
    STUBS.each do |stub|
      remove_request_stub stub
    end
  end

  def test_links_pagination
    VARIATIONS.each do |s|
      Link.create(url: "http://github.com/inertia186/cobblebot?#{s}=#{s}")
    end

    integrated_admin_sign_in

    stub_github do
      stub_mit do
        get admin_links_url
        get admin_links_url(query: 'github', per_page: 1)
      end
  end

    ["admin/links/_link_row", "admin/links/index", "layouts/application"].each do |template|
      assert_template template
    end
  end
end
