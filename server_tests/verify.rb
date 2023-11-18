require 'minitest/autorun'

require_relative '../main'
require_relative '../verify'

# Tests network verification functions
class VerifyTest < Minitest::Test
  def test_validate_hostname
    validate_hostname('localhost')
  end
end
