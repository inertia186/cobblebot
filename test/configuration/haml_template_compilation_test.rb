require 'test_helper'
require 'tilt'

class HamlTemplateCompilationTest < ActiveSupport::TestCase
  def test_all_application_haml_templates_compile
    templates = Rails.root.glob('app/views/**/*.haml')
    assert templates.any?, 'expected application Haml templates'

    templates.each do |path|
      assert_respond_to Tilt.new(path.to_s), :render, path.relative_path_from(Rails.root).to_s
    end
  end
end
