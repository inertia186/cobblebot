require "test_helper"

class TopicsTest < AcceptanceTest
  def test_basic_workflow
    topic = Message::Topic.create!(
      body: 'Representative acceptance topic',
      author: players(:inertia186),
      recipient_term: '@a'
    )

    Server.mock_mode(up: true) do
      visit '/topics'

      assert page.has_no_content?('Searching ...'), 'did not expect "Searching ..." text showing'
      assert_selector 'table > tbody > tr', minimum: 2
      assert page.has_content?(topic.body), 'expected representative topic data'
      assert page.has_content?(topic.author.nick), 'expected topic author data'
    end
  end
end
