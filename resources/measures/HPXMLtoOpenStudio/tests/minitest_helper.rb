require 'simplecov'
require 'codecov'

# save to CircleCI's artifacts directory if we're on CircleCI
if ENV['CI']
  if ENV['CIRCLE_ARTIFACTS']
    dir = File.join(ENV['CIRCLE_ARTIFACTS'], "coverage")
    SimpleCov.coverage_dir(dir)
  end
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
  SimpleCov.start
else
  SimpleCov.coverage_dir("coverage")
  SimpleCov.start
end
require 'minitest/autorun'
require 'minitest/reporters'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new # spec-like progress
