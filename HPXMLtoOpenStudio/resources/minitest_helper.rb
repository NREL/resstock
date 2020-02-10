called_from_cli = true
begin
  OpenStudio.getOpenStudioCLI
rescue
  called_from_cli = false
end

if not called_from_cli # cli can't load codecov gem
  require 'simplecov'
  require 'codecov'

  # save to CircleCI's artifacts directory if we're on CircleCI
  if ENV['CI']
    if ENV['CIRCLE_ARTIFACTS']
      dir = File.join(ENV['CIRCLE_ARTIFACTS'], "coverage")
      SimpleCov.coverage_dir(dir)
    end
    SimpleCov.formatter = SimpleCov::Formatter::Codecov
  else
    SimpleCov.coverage_dir("coverage")
  end
  SimpleCov.start

  require 'minitest/autorun'
  require 'minitest/reporters'

  Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new # spec-like progress
end
