# frozen_string_literal: true

called_from_cli = true
begin
  OpenStudio.getOpenStudioCLI
rescue
  called_from_cli = false
end

require 'minitest/autorun'

if not called_from_cli # cli can't load minitest-reporters gem
  require 'minitest/reporters'

  Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new # spec-like progress
end
