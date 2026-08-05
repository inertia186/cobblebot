require 'test_helper'
require Rails.root.join('db/migrate/20260805000000_remove_translate_callback').to_s

class RemoveTranslateCallbackTest < ActiveSupport::TestCase
  def test_up_deletes_only_the_system_translate_callback
    system_translate = create_callback(name: 'Translate', system: true)
    custom_translate = create_callback(name: 'Translate', system: false)
    other_system_callback = create_callback(name: 'Migration Control', system: true)

    RemoveTranslateCallback.new.migrate(:up)

    refute ServerCallback.exists?(system_translate.id)
    assert ServerCallback.exists?(custom_translate.id)
    assert ServerCallback.exists?(other_system_callback.id)
  end

  def test_down_is_irreversible
    assert_raises ActiveRecord::IrreversibleMigration do
      RemoveTranslateCallback.new.migrate(:down)
    end
  end

private
  def create_callback(name:, system:)
    RemoveTranslateCallback::MigrationServerCallback.create!(
      type: 'ServerCallback::PlayerCommand',
      name: name,
      pattern: '/migration-test/',
      command: 'true',
      system: system
    )
  end
end
