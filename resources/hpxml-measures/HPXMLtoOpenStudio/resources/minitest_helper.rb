# frozen_string_literal: true

require 'minitest/autorun'

require 'minitest/reporters'
require 'minitest/reporters/spec_reporter' # Needed when run via OS CLI

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new # spec-like progress
