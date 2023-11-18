require 'minitest/autorun'
require 'rack/test'
require 'nokogiri'

require_relative '../main'

# Endpoint tests that require a valid access token
class AuthenticatedTest < Minitest::Test
  include Rack::Test::Methods

  def setup
    payload = { email: 'ericshane@eradman.com' }
    @access_token = "access_token=#{JWT.encode(payload, hmac_secret, 'HS256')}"
  end

  def app
    Sinatra::Application
  end

  def test_get_install_sitecode_id
    get '/install/5c188e73-bbc8-4c1b-96c2-d4a195bd6cef'
    assert_equal last_response.status, 401

    set_cookie @access_token
    get '/install/5c188e73-bbc8-4c1b-96c2-d4a195bd6cef'
    assert_equal last_response.status, 200
    assert_equal last_response.content_type, 'text/html;charset=utf-8'
  end

  def test_post_install_sitecode_id
    post '/install/5c188e73-bbc8-4c1b-96c2-d4a195bd6cef'
    assert_equal last_response.status, 401

    set_cookie @access_token
    form_data = {
      email: 'ericshane@eradman.com',
      domains: "eradman.com\r\nscriptedconfiguration.org"
    }
    post '/install/5c188e73-bbc8-4c1b-96c2-d4a195bd6cef', form_data
    assert_equal last_response.status, 200
    assert_equal last_response.content_type, 'text/html;charset=utf-8'
  end

  def test_get_sitecodes
    set_cookie @access_token
    get '/sitecodes'
    assert_equal last_response.status, 200
    assert_equal last_response.content_type, 'text/html;charset=utf-8'
    doc = Nokogiri::HTML(last_response.body)
    h2_tag = doc.css('h2')[0].text
    assert_match(/5c188e73-bbc8-4c1b-96c2-d4a195bd6cef/, h2_tag)
  end

  def test_get_support
    get '/support'
    assert_equal last_response.status, 401

    set_cookie @access_token
    get '/support'
    assert_equal last_response.status, 200
    assert_equal last_response.content_type, 'text/html;charset=utf-8'
    doc = Nokogiri::HTML(last_response.body)
    h1_tag = doc.at_css('h1').text
    assert_match(/Current Issues/, h1_tag)
  end

  # REST API

  def test_patch_account
    data = {
      email: 'ericshane@eradman.com',
      username: 'esr',
      home_page: 'http://eradman.com'
    }

    patch '/account', data.to_json, 'CONTENT_TYPE' => 'application/json'
    assert_equal last_response.status, 401

    set_cookie @access_token
    patch '/account', data.to_json, 'CONTENT_TYPE' => 'application/json'
    assert last_response.ok?
    assert_equal last_response.content_type, 'application/json'
    assert last_response.body.to_json
  end

  def test_post_reply
    set_cookie @access_token
    data = {
      ticket_id: 50,
      comment_area: '??'
    }
    post '/reply', data.to_json, 'CONTENT_TYPE' => 'application/json'
    assert last_response.ok?
    assert_equal last_response.content_type, 'application/json'
    assert last_response.body.to_json['reply_id']
  end

  def test_put_tag
    # ticket
    data = {
      ticket_id: 50,
      tag: 'typo-hawlk'
    }
    set_cookie @access_token
    put '/tag', data.to_json, 'CONTENT_TYPE' => 'application/json'
    assert last_response.ok?
    assert_equal last_response.content_type, 'application/json'
    assert last_response.body['tag_id']

    # issue
    data = {
      ticket_id: 52,
      tag: 'new-feature'
    }
    set_cookie @access_token
    put '/tag', data.to_json, 'CONTENT_TYPE' => 'application/json'
    assert last_response.ok?
    assert_equal last_response.content_type, 'application/json'
    assert last_response.body['tag_id']
  end
end
