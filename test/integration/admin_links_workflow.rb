require 'test_helper'
 
class AdminLinksTest < ActionDispatch::IntegrationTest
  VARIATIONS = %w(a b c d e f g)
  
  def setup
    stub_request(:head, "http://www.mit.edu/").
      to_return(status: 200)
    stub_request(:head, "http://github.com/inertia186/cobblebot").
      to_return(status: 200)
    
    VARIATIONS.each do |s|
      stub_request(:get, "http://github.com/inertia186/cobblebot?#{s}=#{s}").
        to_return(status: 200)
    end
  end
  
  def test_links_pagination
    VARIATIONS.each do |s|
      Link.create(url: "http://github.com/inertia186/cobblebot?#{s}=#{s}")
    end
    
    integrated_admin_sign_in
    
    get admin_links_url
    get admin_links_url(query: 'github', per_page: 1)
    
    ["admin/links/_link_row", "admin/links/index", "layouts/application"].each do |template|
      assert_template template
    end
  end
end
