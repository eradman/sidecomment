require 'resolv'

def validate_hostname(address)
  sleep 0.5 if Sinatra::Base.environment == :production
  Resolv.getaddress address
end
