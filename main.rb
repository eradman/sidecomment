require 'sinatra'
require 'sinatra/cookies'
require 'tilt/haml'
require 'json'
require 'jwt'
require 'uri'

set :haml, format: :html5
set :show_exceptions, false
disable :protection # Don't set the 'X-Xss-Protection' header

require_relative 'data'
require_relative 'messaging'
require_relative 'verify'

# authentication

def hmac_secret
  @hmac_secret ||= File.read('.hmac_secret').strip
end

def encode_acces_token(email)
  payload = { 'email' => email }
  JWT.encode(payload, hmac_secret, 'HS256')
end

def read_access_token(token)
  if token.nil? || token.empty?
    { 'error' => '' }
  else
    JWT.decode(token, hmac_secret, true, { algorithm: 'HS256' })[0]
  end
rescue JWT::DecodeError => e
  { 'error' => e.message }
end

# site configuration

def local_sitecode
  @local_sitecode ||= File.read('.local_sitecode').strip
end

# error handling

not_found do
  status 404
end

error do
  env['sinatra.error'].message
end

# comment route

get '/' do
  redirect to('/comment')
end

get '/plans' do
  decoded_token = read_access_token(cookies[:access_token])
  haml :plans, locals: { local_sitecode: local_sitecode,
                         usercode: '',
                         message: '',
                         decoded_token: decoded_token }
end

get '/comment' do
  decoded_token = read_access_token(cookies[:access_token])
  haml :comment, locals: { local_sitecode: local_sitecode,
                           usercode: '',
                           message: '',
                           decoded_token: decoded_token }
end

post '/comment' do
  decoded_token = read_access_token(cookies[:access_token])
  begin
    validate_hostname(params[:hostname])
    usercode = generate_usercode(params[:email], params[:hostname])
    if decoded_token['email'].nil?
      otp = reset_otp(params['email'])
      send_usercode_confirmation(params[:email], params['hostname'], usercode, otp)
      message = 'Usercode confirmation sent by email.'
    else
      active = activate_user(usercode)
      raise "usercode #{usercode} not found" unless active == 't'

      message = 'Usercode authorized'
    end
  rescue StandardError => e
    message = e.to_s
    message = "ERROR: #{message}" unless message.include? 'ERROR'
  end
  haml :comment, locals: { local_sitecode: local_sitecode,
                           usercode: usercode,
                           params: params,
                           message: message,
                           decoded_token: decoded_token }
end

# install route

get '/install' do
  decoded_token = read_access_token(cookies[:access_token])
  haml :install, locals: { local_sitecode: local_sitecode,
                           sitecode_id: '',
                           params: params,
                           message: '',
                           decoded_token: decoded_token }
end

post '/install' do
  decoded_token = read_access_token(cookies[:access_token])
  domains = params[:domains].split(/\r?\n/)
  begin
    domains.each { |hostname| validate_hostname(hostname) }
    sitecode = register_site(params[:email], domains)
    otp = reset_otp(params[:email])
    send_sitecode_confirmation(params[:email], domains, sitecode, otp)
    message = 'Sitecode confirmation sent by email.'
  rescue StandardError => e
    message = e.to_s
    message = "ERROR: #{message}" unless message.include? 'ERROR'
  end
  haml :install, locals: { local_sitecode: local_sitecode,
                           sitecode_id: sitecode,
                           params: params,
                           message: message,
                           decoded_token: decoded_token }
end

get '/install/:sitecode_id' do
  decoded_token = read_access_token(cookies[:access_token])
  halt 401, decoded_token['error'] if decoded_token.key?('error')

  registration = fetch_registration(params['sitecode_id'])
  haml :install, locals: { local_sitecode: local_sitecode,
                           sitecode_id: params['sitecode_id'],
                           registration: registration,
                           message: '',
                           decoded_token: decoded_token }
end

post '/install/:sitecode_id' do
  decoded_token = read_access_token(cookies[:access_token])
  halt 401, decoded_token['error'] if decoded_token.key?('error')
  domains = params[:domains].split(/\r?\n/)
  begin
    domains.each { |hostname| validate_hostname(hostname) }
    registration = update_site(params['sitecode_id'], domains)
    message = 'Domain Names updated'
  rescue StandardError => e
    message = e.to_s
    message = "ERROR: #{message}" unless message.include? 'ERROR'
  end
  haml :install, locals: { local_sitecode: local_sitecode,
                           sitecode_id: params['sitecode_id'],
                           registration: registration,
                           message: message,
                           decoded_token: decoded_token }
end

# tickets route

get '/tickets/:token' do
  decoded_token = read_access_token(cookies[:access_token])
  account = fetch_account(params['token'], :usercode)
  halt 404, 'Usercode not found' if account.nil?
  tickets = fetch_tickets(params['token'])
  authenticated_email = decoded_token['email'] || nil
  haml :tickets, locals: { local_sitecode: local_sitecode,
                           authenticated_email: authenticated_email,
                           tickets: tickets,
                           account: account,
                           decoded_token: decoded_token }
end

# account route

set(:otp) { |value| condition { params[:otp].nil? == value.nil? } }

get '/account', :otp => true do
  otp = params[:otp]
  sitecode = params[:sitecode]
  usercode = params[:usercode]

  email = email_for_otp(otp)
  token = encode_acces_token(email)
  cookies[:access_token] = token
  next_path = '/account'

  if sitecode&.length&.positive?
    active = activate_site(sitecode)
    next_path = '/sitecodes'
    raise "sitecode #{sitecode} not found" unless active == 't'
  end

  if usercode&.length&.positive?
    active = activate_user(usercode)
    next_path = "/tickets/#{usercode}"
    raise "usercode #{usercode} not found" unless active == 't'
  end

  reset_otp(email)
  redirect to(next_path)

  decoded_token = read_access_token(cookies[:access_token])
  account = fetch_account(decoded_token['email'], :email)
  haml :account, locals: { local_sitecode: local_sitecode,
                           account: account,
                           decoded_token: decoded_token }
end

get '/account' do
  decoded_token = read_access_token(cookies[:access_token])
  account = fetch_account(decoded_token['email'], :email)
  haml :account, locals: { local_sitecode: local_sitecode,
                           account: account,
                           decoded_token: decoded_token }
end

post '/account' do
  decoded_token = read_access_token(cookies[:access_token])
  otp = reset_otp(params[:email])
  send_one_time_login(params[:email], otp)
  haml :account, locals: { local_sitecode: local_sitecode,
                           decoded_token: decoded_token }
end

# sitecodes route

get '/sitecodes' do
  decoded_token = read_access_token(cookies[:access_token])
  sitecodes = fetch_sitecodes(decoded_token['email'])
  haml :sitecodes, locals: { local_sitecode: local_sitecode,
                             sitecodes: sitecodes,
                             decoded_token: decoded_token }
end

get '/user/:username' do
  decoded_token = read_access_token(cookies[:access_token])
  account = fetch_account(params['username'], :username)
  user_stats = fetch_user_stats(account['email'])
  haml :user_partial, locals: { local_sitecode: local_sitecode,
                                account: account,
                                account_details: params['account_details'],
                                user_stats: user_stats,
                                decoded_token: decoded_token }
end

# support routes

get '/support' do
  decoded_token = read_access_token(cookies[:access_token])
  halt 401, decoded_token if decoded_token.key?('error')
  haml :support, locals: { local_sitecode: local_sitecode,
                           decoded_token: decoded_token }
end

post '/support' do
  decoded_token = read_access_token(cookies[:access_token])
  halt 401, decoded_token if decoded_token.key?('error')

  origin = if env.key? 'HTTP_ORIGIN'
             URI.parse(env['HTTP_ORIGIN']).host
           else
             request.host # incorrect, for testing only
           end
  create_issue(decoded_token['email'], origin, params)
  haml :support, locals: { local_sitecode: local_sitecode,
                           decoded_token: decoded_token }
end

# logout route

get '/logout' do
  cookies[:access_token] = nil
  redirect to('/account')
end

#
# Async requests
#

get '/replies/:ticket_id' do
  replies = fetch_replies(params['ticket_id'])
  haml :replies_partial, locals: { replies: replies }
end

post '/reply' do
  content_type :json
  decoded_token = read_access_token(cookies[:access_token])
  halt 401, decoded_token if decoded_token.key?('error')

  begin
    data = JSON.parse(request.body.read)
    r = create_reply(request.host, decoded_token['email'], data)
    r[0].to_json
  rescue StandardError => e
    { error: e }.to_json
  end
end

patch '/account' do
  content_type :json
  decoded_token = read_access_token(cookies[:access_token])
  halt 401, decoded_token if decoded_token.key?('error')

  begin
    data = JSON.parse(request.body.read)
    r = update_account(decoded_token['email'], data)
    r.to_json
  rescue StandardError => e
    { error: e }.to_json
  end
end

get '/ticket_summary/:sitecode_id' do
  decoded_token = read_access_token(cookies[:access_token])
  halt 401, decoded_token['error'] if decoded_token.key?('error')
  tickets = fetch_ticket_summary(params['sitecode_id'])
  haml :ticket_summary_partial, locals: { tickets: tickets }
end

get '/issue_summary/:sitecode_id' do
  decoded_token = read_access_token(cookies[:access_token])
  halt 401, decoded_token['error'] if decoded_token.key?('error')
  tickets = fetch_issue_summary(params['sitecode_id'])
  haml :issue_summary_partial, locals: { tickets: tickets }
end

patch '/ticket/:ticket_id' do
  content_type :json
  decoded_token = read_access_token(cookies[:access_token])
  halt 401, decoded_token if decoded_token.key?('error')

  begin
    JSON.parse(request.body.read)
    r = close_ticket(params['ticket_id'])
    if r['url'].nil?
      send_issue_close_summary(params['ticket_id'])
    else
      send_ticket_close_summary(params['ticket_id'])
    end
    r.to_json
  rescue StandardError => e
    { error: e }.to_json
  end
end

# Cross-Origin requests

options '*' do
  response.headers['Access-Control-Allow-Origin'] = '*'
  response.headers['Access-Control-Allow-Methods'] = 'POST'
  response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
  200
end

post '/ticket' do
  response.headers['Access-Control-Allow-Origin'] = env['HTTP_ORIGIN']
  response.headers['Access-Control-Allow-Methods'] = 'POST'
  content_type :json

  origin = if env.key? 'HTTP_ORIGIN'
             URI.parse(env['HTTP_ORIGIN']).host
           else
             request.host # incorrect, for testing only
           end
  begin
    data = JSON.parse(request.body.read)
    data['base'] ||= ''
    data['extent'] ||= ''
    data['selection'] ||= ''
    r = create_ticket(origin, data)
    raise 'sitecode key does not match hostname' unless r

    r.to_json
  rescue StandardError => e
    { error: e }.to_json
  end
end
