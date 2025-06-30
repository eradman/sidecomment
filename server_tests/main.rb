require 'rack/test'
require 'nokogiri'

require_relative '../main'

# Tests actions that do not require a user to be authorized
class MainTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup_once
    dbname = 'test_main'
    db.exec("CREATE DATABASE #{dbname} TEMPLATE test_0;")
    $pg_url_alt = "#{$pg_url}&dbname=#{dbname}"
  end

  def setup
    @@setup_once ||= setup_once
    set_cookie 'access_token='
  end

  def test_get_index
    get '/'
    assert_equal last_response.status, 302
    assert_equal last_response.headers['Location'], 'http://example.org/comment'
  end

  def test_get_comment
    get '/comment'
    assert last_response.ok?
    assert_equal last_response.content_type, 'text/html;charset=utf-8'
  end

  def test_get_install
    get '/install'
    assert last_response.ok?
    assert_equal last_response.content_type, 'text/html;charset=utf-8'
    doc = Nokogiri::HTML(last_response.body)
    refute doc.at_css('p#status')
  end

  def test_post_install
    form_data = {
      email: 'ericshane@eradman.com',
      domains: "eradman.com\r\nscriptedconfiguration.org"
    }
    post '/install', form_data
    assert last_response.ok?
    assert_equal last_response.content_type, 'text/html;charset=utf-8'
    doc = Nokogiri::HTML(last_response.body)
    assert_match 'Sitecode confirmation sent', doc.at_css('p#status').text
  end

  def test_get_tickets
    get '/tickets/XXXXX'
    assert_equal last_response.status, 404

    get '/tickets/4dEo73XK2T8'
    assert last_response.ok?
    assert_equal last_response.content_type, 'text/html;charset=utf-8'
    doc = Nokogiri::HTML(last_response.body)
    assert_match(/eradman/, doc.at_css('div#author').text)

    get '/tickets/hFNjWv2phA8'
    assert last_response.ok?
    assert_equal last_response.content_type, 'text/html;charset=utf-8'
    doc = Nokogiri::HTML(last_response.body)
    assert_match(/ericshane/, doc.at_css('div#author').text)
  end

  def test_get_replies
    get '/replies/10'
    assert last_response.ok?
    assert_equal last_response.content_type, 'text/html;charset=utf-8'
  end

  def test_get_account
    get '/account'
    assert last_response.ok?
    assert_equal last_response.content_type, 'text/html;charset=utf-8'
  end

  def test_get_account_login
    otp = reset_otp('ericshane@eradman.com')
    get '/account', { 'otp' => otp }
    assert_equal last_response.status, 302
    assert_equal last_response.headers['Location'], 'http://example.org/account'
    assert_match(/access_token=.+;/, last_response.headers['Set-Cookie'])
  end

  def test_get_account_verify_sitecode_a
    otp = reset_otp('ericshane@eradman.com')
    sitecode = '7be302ad-726e-4471-832c-f6691b9b9335'
    get '/account', { 'otp' => otp, 'sitecode' => sitecode }
    assert_equal last_response.status, 302
    assert_equal last_response.headers['Location'], 'http://example.org/sitecodes'
    assert_match(/access_token=.+;/, last_response.headers['Set-Cookie'])
  end

  def test_get_account_verify_sitecode_b
    otp = reset_otp('ericshane@eradman.com')
    sitecode = '7be302ad-726e-4471-832c-f6691b9b9335'
    get '/account', { 'otp' => otp, 'sitecode' => sitecode }
    follow_redirect!
    assert_equal last_response.status, 200
    doc = Nokogiri::HTML(last_response.body)
    h2_tag = doc.css('h2')[1].text
    assert_match(/7be302ad-726e-4471-832c-f6691b9b9335/, h2_tag)
  end

  def test_get_logout
    get '/logout'
    assert_equal last_response.status, 302
    assert_equal last_response.headers['Location'], 'http://example.org/account'
    assert_match(/access_token=;/, last_response.headers['Set-Cookie'])
  end

  def test_get_user
    get '/user/eradman'
    assert last_response.ok?
    assert_equal last_response.content_type, 'text/html;charset=utf-8'

    get '/user/eradman?account_details=1'
    assert last_response.ok?
    assert_equal last_response.content_type, 'text/html;charset=utf-8'
  end

  # Cross-Origin requests

  def test_options
    options '/ticket'
    assert last_response.ok?
    assert_equal last_response.headers, {
      'Access-Control-Allow-Origin' => '*',
      'Access-Control-Allow-Methods' => 'POST',
      'Access-Control-Allow-Headers' => 'Content-Type',
      'Content-Type' => 'text/html;charset=utf-8',
      'Content-Length' => '0'
    }
  end

  def test_post_ticket
    data = {
      usercode_id: 'hFNjWv2phA8',
      sitecode_id: '5c188e73-bbc8-4c1b-96c2-d4a195bd6cef',
      url: 'http://localhost/',
      base: 'A title',
      selection: 'Like',
      extent: 'no Other',
      comment_area: '??'
    }
    post '/ticket', data.to_json, 'CONTENT_TYPE' => 'application/json'
    assert last_response.ok?
    assert_equal last_response.content_type, 'application/json'
    assert_nil last_response.headers['Access-Control-Allow-Origin']
    assert_equal last_response.headers['Access-Control-Allow-Methods'], 'POST'
    assert last_response.body['ticket_id']
  end
end
