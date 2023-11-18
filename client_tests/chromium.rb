require 'ferrum'

# A custom logging class that captures runtime exceptions
class FerrumLogger
  attr_reader :exceptions

  def initialize
    @log = File.open("/tmp/cdp.trace.#{Time.now.to_i}", 'w')
  end

  def truncate
    @exceptions = []
  end

  def puts(log_line)
    _log_symbol, _log_time, log_body = log_line.strip.split(' ', 3)
    log_detail = JSON.parse(log_body)
    @log.write(log_line)
    return unless log_detail['method'] == 'Runtime.exceptionThrown'

    params = log_detail['params']
    @exceptions << params['exceptionDetails']['exception']['description']
  end
end

# Set up for tests using Chrome DevTools Protocol
module Chromium
  class << self
    def browser
      options = {
        headless: true,
        logger: FerrumLogger.new
      }
      Dir.chdir('/tmp') do
        @browser ||= Ferrum::Browser.new options
      end
    end
  end
end
