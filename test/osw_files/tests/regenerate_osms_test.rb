require_relative '../../minitest_helper'
require_relative '../../regenerate_osms'
require 'minitest/autorun'

class TestRegenerateTestOSMs < MiniTest::Test
  def test_regenerate_osms
    begin
      regenerate_osms
    rescue Exception => e
      flunk e

      # Need a backtrace? Uncomment below
      # flunk "#{e}\n#{e.backtrace.join('\n')}"
    end
  end
end
