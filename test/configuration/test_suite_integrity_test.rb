require 'test_helper'
require 'tempfile'

class TestSuiteIntegrityTest < ActiveSupport::TestCase
  def test_test_methods_are_not_redefined_within_a_class
    duplicates = duplicate_test_methods(
      Dir[Rails.root.join('test/**/*_test.rb')]
    )

    assert_empty duplicates, <<~MESSAGE
      Duplicate test methods are silently overwritten by Ruby:
      #{duplicates.join("\n")}
    MESSAGE
  end

  def test_duplicate_scan_combines_reopened_class_declarations
    files = 2.times.map do |index|
      Tempfile.new(["reopened-test-#{index}", '.rb']).tap do |file|
        file.write(<<~RUBY)
          class ReopenedTest < ActiveSupport::TestCase
            def test_redefined
            end
          end
        RUBY
        file.close
      end
    end

    duplicates = duplicate_test_methods(files.map(&:path))

    assert_equal 1, duplicates.length
    assert_includes duplicates.first, 'ReopenedTest#test_redefined'
  ensure
    files&.each(&:close!)
  end

private
  def duplicate_test_methods(paths)
    definitions = paths.flat_map do |path|
      syntax_tree = RubyVM::AbstractSyntaxTree.parse_file(path)
      class_nodes(syntax_tree).flat_map do |class_node|
        class_name = constant_name(class_node.children.fetch(0))
        direct_test_definitions(class_node.children.fetch(2)).map do |definition|
          {
            class_name: class_name,
            method_name: definition.children.fetch(0),
            path: path,
            line: definition.first_lineno
          }
        end
      end
    end

    definitions.group_by { |definition|
      [definition.fetch(:class_name), definition.fetch(:method_name)]
    }.select { |_identity, matches| matches.many? }.map do |identity, matches|
      locations = matches.map do |definition|
        path = Pathname(definition.fetch(:path))
        display_path = if path.to_s.start_with?(Rails.root.to_s)
          path.relative_path_from(Rails.root)
        else
          path
        end
        "#{display_path}:#{definition.fetch(:line)}"
      end
      "#{identity.first}##{identity.last} at #{locations.join(', ')}"
    end
  end

  def class_nodes(node)
    return [] unless node.is_a?(RubyVM::AbstractSyntaxTree::Node)

    current = node.type == :CLASS ? [node] : []
    current + node.children.flat_map { |child| class_nodes(child) }
  end

  def direct_test_definitions(node)
    return [] unless node.is_a?(RubyVM::AbstractSyntaxTree::Node)
    return [] if [:CLASS, :MODULE].include?(node.type)

    current = if node.type == :DEFN && node.children.fetch(0).to_s.start_with?('test_')
      [node]
    else
      []
    end
    current + node.children.flat_map { |child| direct_test_definitions(child) }
  end

  def constant_name(node)
    case node.type
    when :CONST
      node.children.fetch(0).to_s
    when :COLON2
      parent, name = node.children
      [parent && constant_name(parent), name].compact.join('::')
    when :COLON3
      "::#{node.children.fetch(0)}"
    else
      raise "Unsupported class name syntax: #{node.type}"
    end
  end
end
