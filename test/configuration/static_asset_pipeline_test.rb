require 'test_helper'

class StaticAssetPipelineTest < Minitest::Test
  VENDORED_REFERENCES = %w[
    bootstrap/glyphiconshalflings-regular.eot
    bootstrap/glyphiconshalflings-regular.svg
    bootstrap/glyphiconshalflings-regular.ttf
    bootstrap/glyphiconshalflings-regular.woff
    chosen/chosen-sprite.png
    chosen/chosen-sprite@2x.png
  ].freeze

  def test_bundle_and_asset_load_paths_do_not_require_sass
    refute_includes File.read(Rails.root.join('Gemfile.lock')), 'sassc'
    assert_empty Dir[Rails.root.join('{app,lib,vendor}', '**', '*.{sass,scss}').to_s]
    assert File.exist?(Rails.root.join('docs/archive/application.legacy.css.scss'))
  end

  def test_application_assets_compile_and_vendor_references_are_digested
    environment = Rails.application.assets
    stylesheet = environment.find_asset('application.css')

    refute_nil stylesheet
    refute_nil environment.find_asset('application.js')
    refute_nil environment.find_asset('logo-24.png')

    css = stylesheet.to_s
    VENDORED_REFERENCES.each do |logical_path|
      asset = environment.find_asset(logical_path)

      refute_nil asset, "expected #{logical_path} to resolve"
      assert_includes css, "/assets/#{asset.digest_path}"
    end
  end

  def test_manifest_publishes_vendor_fonts_and_images
    manifest = File.read(Rails.root.join('app/assets/config/manifest.js'))

    assert_includes manifest, 'link_tree ../../../vendor/assets/fonts'
    assert_includes manifest, 'link_tree ../../../vendor/assets/images'
  end

  def test_cancel_on_navigate_dependencies_are_safe_to_minify
    source = File.read(Rails.root.join('app/assets/javascripts/angularCancelOnNavigateModule.js'))

    assert_includes source, ".config(['$httpProvider'"
    assert_includes source, ".run(['$rootScope', 'HttpPendingRequestsService'"
    assert_includes source, ".service('HttpPendingRequestsService', ['$q'"
    assert_includes source, ".factory('HttpRequestTimeoutInterceptor', ['$q', 'HttpPendingRequestsService'"
  end
end
