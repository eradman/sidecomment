require 'resolv'

def validate_hostname(address)
  sleep 0.5 if ENV['RACK_ENV'] == 'production'
  Resolv.getaddress address
end
