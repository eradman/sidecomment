require_relative '../notify'

# Tests actions that are initiated by a background schedule
class NotifyTest < Minitest::Test
  def setup_once
    dbname = 'test_notify'
    db.exec("CREATE DATABASE #{dbname} TEMPLATE test_0;")
    $pg_url_alt = "#{$pg_url}&dbname=#{dbname}"
  end

  def setup
    @@setup_once ||= setup_once
  end

  def test_api_notify_tickets
    tickets = notify_tickets
    expected = [
      {
        'sitecode_email' => 'ericshane@eradman.com',
        'sitecode_id' => '5c188e73-bbc8-4c1b-96c2-d4a195bd6cef',
        'hostname' => 'raticalsoftware.com',
        'usercode_ids' => '{4dEo73XK2T8}',
        'count' => '1'
      }
    ]
    assert_equal(expected, tickets.map { |entry| entry })
  end

  def test_api_notify_replies
    replies = notify_replies.map { |entry| entry.slice('account_email', 'usercode_id') }
    expected = [
      { 'account_email' => 'eradman@eradman.com', 'usercode_id' => '4dEo73XK2T8' },
      { 'account_email' => 'ericshane@eradman.com', 'usercode_id' => '4dEo73XK2T8' },
      { 'account_email' => 'ericshane@eradman.com', 'usercode_id' => '4dEo73XK2T8' },
      { 'account_email' => 'hostmaster@raticalsoftware.com', 'usercode_id' => '4dEo73XK2T8' }
    ]
    assert_equal(expected, replies.map { |entry| entry.slice('account_email', 'usercode_id') })
  end
end
