require 'minitest/autorun'
require 'minitest/utils'
require 'rack/test'

require_relative '../data'

$test_count = 0

# Test helper functions that interact with the database
class DataTest < Minitest::Test
  def setup
    dbname = "test_#{$test_count += 1}"
    db.exec("CREATE DATABASE #{dbname} TEMPLATE test_0;")
    $pg_url_alt = "#{$pg_url}&dbname=#{dbname}"
  end

  # trigger procedures
  def test_insert_account_trigger
    db.exec %{
      INSERT INTO sitecode (email, domains)
      VALUES ('root@eradman.com', '{eradman.com}');
    }
    r = db.exec %(
      SELECT username
      FROM account
      WHERE username ~ 'root'
      ORDER BY username
    )
    assert_equal 'root', r[0]['username']
    assert_match(/root[0-9]{3}/, r[1]['username'])
  end

  # system tasks

  def test_prune_usercodes
    db.exec %{ CALL prune_usercodes('30 days'::interval); }

    r = db.exec %( select * FROM usercode; )
    assert_equal 3, r.count
  end

  def test_archive_tickets
    db.exec %{ CALL archive_tickets('30 days'::interval); }

    r = db.exec %( select * FROM archive.ticket; )
    assert_equal 4, r.count
    r = db.exec %( select * FROM archive.usercode; )
    assert_equal 3, r.count
  end

  # data functions

  def test_query_usercode
    expected = ['raticalsoftware.com']
    found = usercode('4dEo73XK2T8')[0].values_at('hostname')
    assert_equal expected, found
  end

  def test_generate_usercode
    token = generate_usercode('ericshane@eradman.com', 'raticalsoftware.com')
    assert token.length == 11
  end

  def test_create_ticket
    data = {
      'usercode_id' => 'hFNjWv2phA8',
      'sitecode_id' => '5c188e73-bbc8-4c1b-96c2-d4a195bd6cef',
      'url' => 'http://raticalsoftware.com/install',
      'base' => 'Quick',
      'selection' => 'Start',
      'extent' => '!',
      'comment_area' => "no caps'"
    }
    create_ticket('example.org', data)
  end

  def test_fetch_tickets
    expected = [
      { 'ticket_id' => '50',
        'created' => 'August 07, 2021',
        'url' => 'http://raticalsoftware.com/',
        'base' => 'Resume: ',
        'selection' => 'HTML | PDF',
        'extent' => '',
        'comment_area' => 'Add TXT',
        'topic' => nil,
        'usercode_email' => 'eradman@eradman.com',
        'sitecode_email' => 'ericshane@eradman.com',
        'closed' => nil,
        'username' => 'eradman' },
      { 'ticket_id' => '51',
        'created' => 'August 08, 2021',
        'url' => 'http://raticalsoftware.com/',
        'base' => 'Resuem:', 'selection' => 'HTML | PDF',
        'extent' => '',
        'comment_area' => 'Add TXT',
        'topic' => nil,
        'usercode_email' => 'eradman@eradman.com',
        'sitecode_email' => 'ericshane@eradman.com',
        'username' => 'eradman',
        'closed' => 'August 08, 2021' }
    ]
    fetch_tickets('4dEo73XK2T8').each do |row|
      assert_equal expected.pop, row
    end
  end

  def test_fetch_ticket_a
    expected = {
      'ticket_id' => '50',
      'created' => 'August 07, 2021',
      'url' => 'http://raticalsoftware.com/',
      'base' => 'Resume: ',
      'selection' => 'HTML | PDF',
      'extent' => '',
      'comment_area' => 'Add TXT',
      'author' => 'eradman@eradman.com',
      'username' => 'eradman',
      'closed' => nil,
      'sitecode_id' => '5c188e73-bbc8-4c1b-96c2-d4a195bd6cef',
      'usercode_id' => '4dEo73XK2T8'
    }
    assert_equal fetch_ticket(50), expected
  end

  def test_fetch_ticket_b
    expected = {
      'ticket_id' => '51',
      'created' => 'August 08, 2021',
      'url' => 'http://raticalsoftware.com/',
      'base' => 'Resuem:', 'selection' => 'HTML | PDF',
      'extent' => '',
      'comment_area' => 'Add TXT',
      'author' => 'eradman@eradman.com',
      'username' => 'eradman',
      'closed' => 'August 08, 2021',
      'sitecode_id' => '5c188e73-bbc8-4c1b-96c2-d4a195bd6cef',
      'usercode_id' => '4dEo73XK2T8'
    }
    assert_equal expected, fetch_ticket(51)
  end

  def test_fetch_replies
    expected = [
      { 'reply_id' => '21',
        'age' => 'less then 1 hour ago',
        'comment_area' => '80 will print nicely',
        'username' => 'ericshane',
        'new' => 't' },
      { 'reply_id' => '20',
        'age' => 'less then 1 hour ago',
        'comment_area' => '80 cols or 72?',
        'username' => 'ericshane',
        'new' => 't' }
    ]
    fetch_replies(10).each do |row|
      assert_equal expected.pop, row
    end
  end

  def test_create_reply
    params = {
      'ticket_id' => 50,
      'comment_area' => 'looks good'
    }
    expected = [
      { 'reply_id' => '30',
        'ticket_id' => '50' }
    ]
    create_reply('eradman.com', 'eradman@eradman.com', params).each do |row|
      assert_equal expected.pop, row
    end
  end

  def test_register_site
    sitecode_id = register_site('eradman@eradman.com', ['eradman.com'])
    assert sitecode_id

    sitecode_id = update_site(sitecode_id, ['localhost', 'eradman.com'])
    assert sitecode_id
  end

  def test_activate_site
    sitecode_id = activate_site('5c188e73-bbc8-4c1b-96c2-d4a195bd6cef')
    expected = 't'
    assert_equal sitecode_id, expected
  end

  def test_activate_user
    usercode_id = activate_user('hFNjWv2phA8')
    expected = 't'
    assert_equal usercode_id, expected
  end

  def test_fetch_sitecodes
    expected = [
      { 'sitecode_id' => '5c188e73-bbc8-4c1b-96c2-d4a195bd6cef',
        'domains' => '{localhost,example.org,raticalsoftware.com}' }
    ]
    fetch_sitecodes('ericshane@eradman.com').each do |row|
      assert_equal expected.pop, row
    end
  end

  def test_fetch_account
    account = fetch_account('eradman@eradman.com', :email)
    assert_equal account['username'], 'eradman'
    assert_equal account['home_page'], 'http://eradman.com'
    assert_equal account['location'], 'Endicott, NY'
  end

  def test_fetch_registration
    expected = [
      { 'sitecode_id' => '5c188e73-bbc8-4c1b-96c2-d4a195bd6cef',
        'email' => 'ericshane@eradman.com',
        'domains' => '{localhost,example.org,raticalsoftware.com}' }
    ]
    row = fetch_registration('5c188e73-bbc8-4c1b-96c2-d4a195bd6cef')
    assert_equal expected.pop, row
  end

  def test_fetch_ticket_summary
    expected = [
      { 'usercode_id' => '4dEo73XK2T8',
        'url' => 'http://raticalsoftware.com/',
        'created' => 'Aug 07 08:05',
        'author' => 'eradman',
        'replies' => '2',
        'status' => 'open',
        'new' => 'f' },
      { 'usercode_id' => '4dEo73XK2T8',
        'url' => 'http://raticalsoftware.com/',
        'created' => 'Aug 08 10:00',
        'author' => 'eradman', 'replies' => '0',
        'status' => 'closed',
        'new' => 'f' }
    ]
    fetch_ticket_summary('5c188e73-bbc8-4c1b-96c2-d4a195bd6cef').each do |row|
      assert_equal expected.pop, row
    end
  end

  def test_fetch_issue_summary
    expected = [
      { 'usercode_id' => '4dEo73XK2T8',
        'created' => 'Aug 07 08:05',
        'author' => 'eradman',
        'topic' => nil,
        'replies' => '2',
        'status' => 'open',
        'new' => 'f' },
      { 'usercode_id' => '4dEo73XK2T8',
        'created' => 'Aug 08 10:00',
        'author' => 'eradman',
        'topic' => nil,
        'replies' => '0',
        'status' => 'closed',
        'new' => 'f' },
      { 'usercode_id' => 'fmKmGEhDVxM',
        'created' => 'Aug 09 12:02',
        'author' => 'ericshane',
        'topic' => 'Wordpress Config',
        'replies' => '0',
        'status' => 'open',
        'new' => 'f' }
    ]
    fetch_issue_summary('5c188e73-bbc8-4c1b-96c2-d4a195bd6cef').each do |row|
      assert_equal expected.pop, row
    end
  end

  def test_reset_otp
    first = reset_otp('ericshane@eradman.com')
    second = reset_otp('ericshane@eradman.com')
    refute_equal first, second
  end

  def test_update_account
    data = {
      'username' => 'ericshane',
      'home_page' => 'http://eradman.com/'
    }
    r = update_account('ericshane@eradman.com', data)
    assert r['last_auth']
  end

  def test_close_ticket
    r = close_ticket(50)
    assert r['url']
  end

  def test_fetch_user_stats
    expected = [
      { 'name' => '2021', 'count' => '4' }
    ]

    fetch_user_stats('ericshane@eradman.com').each do |row|
      assert_equal expected.pop, row
    end
  end

  def test_create_issue
    data = {
      'sitecode_id' => '5c188e73-bbc8-4c1b-96c2-d4a195bd6cef',
      'topic' => 'Wordpress installation',
      'comment_area' => 'How can I include the scripts?'
    }
    origin = 'raticalsoftware.com'
    create_issue('example.org', origin, data)
  end

  def test_tickets_pending_notification
    expected = [
      {
        'sitecode_email' => 'ericshane@eradman.com',
        'sitecode_id' => '5c188e73-bbc8-4c1b-96c2-d4a195bd6cef',
        'hostname' => 'raticalsoftware.com',
        'usercode_ids' => '{4dEo73XK2T8}',
        'count' => '1'
      }
    ]
    tickets_pending_notification.each do |row|
      assert_equal expected.pop, row
    end
  end

  def test_replies_pending_notification
    expected = [
      { 'account_email' => 'eradman@eradman.com',
        'usercode_id' => '4dEo73XK2T8',
        'ticket_id' => '50',
        'hostname' => 'raticalsoftware.com',
        'reply_ids' => '{20}',
        'count' => '4' },
      { 'account_email' => 'ericshane@eradman.com',
        'usercode_id' => '4dEo73XK2T8',
        'ticket_id' => '50',
        'hostname' => 'raticalsoftware.com',
        'reply_ids' => '{20}',
        'count' => '4' },
      { 'account_email' => 'ericshane@eradman.com',
        'usercode_id' => '4dEo73XK2T8',
        'ticket_id' => '50',
        'hostname' => 'raticalsoftware.com',
        'reply_ids' => '{21}',
        'count' => '4' },
      { 'account_email' => 'hostmaster@raticalsoftware.com',
        'usercode_id' => '4dEo73XK2T8',
        'ticket_id' => '50',
        'reply_ids' => '{21}',
        'hostname' => 'raticalsoftware.com',
        'count' => '4' }
    ]
    expected.reverse!
    replies_pending_notification.each do |row|
      assert_equal expected.pop, row
    end
  end

  def test_mark_ticket_sent
    assert_equal 1, tickets_pending_notification.count
    r = mark_ticket_sent(%w[4dEo73XK2T8 44444444444])
    assert r
    assert_equal 0, tickets_pending_notification.count
  end

  def test_mark_reply_sent
    assert_equal 4, replies_pending_notification.count
    r = mark_reply_sent('hostmaster@raticalsoftware.com', [20, 21])
    assert r
    assert_equal 1, tickets_pending_notification.count
  end

  def test_record_notification
    record_notification('user1@eradman.com', 'Usercode Activation', '10.10.0.1')
    record_notification('user2@eradman.com', 'Usercode Activation', '10.10.0.1')
    record_notification('user4@eradman.com', 'Usercode Activation', '10.10.0.1')
    assert_raises(PG::Error) do
      record_notification('user5@eradman.com', 'Usercode Activation', '10.10.0.1')
    end
  end
end
