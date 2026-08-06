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
        get admin_links_url(query: 'github', per_page: 2, sort_field: 'url', sort_order: 'asc')

        assert_response :success
        assert_select 'table tbody tr', count: 2
        assert_select '.pagination .current', text: '1'

        first_page_ids = css_select('table tbody tr').map { |row| row['data-id'] }
        next_page_path = css_select('.pagination a.next_page').first['href']
        next_page_params = Rack::Utils.parse_query(next_page_path.split('?', 2).last)

        assert_equal '2', next_page_params['page']
        assert_equal '2', next_page_params['per_page']
        assert_equal 'github', next_page_params['query']
        assert_equal 'url', next_page_params['sort_field']
        assert_equal 'asc', next_page_params['sort_order']

        get next_page_path

        assert_response :success
        assert_select 'table tbody tr', count: 2
        assert_select '.pagination .current', text: '2'
        assert_empty first_page_ids & css_select('table tbody tr').map { |row| row['data-id'] }

        get admin_links_url(query: 'mit', per_page: 2)

        assert_response :success
        assert_select 'table tbody tr', count: 1
        assert_select '.pagination', count: 0
      end
    end

    ["admin/links/_link_row", "admin/links/index", "layouts/application"].each do |template|
      assert_template template
    end
  end
end
