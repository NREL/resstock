# frozen_string_literal: true

# This file is only used to run all tests and collect results on the CI.
# All rake tasks have been moved to tasks.rb.

require 'rake'
require 'rake/testtask'
require 'ci/reporter/rake/minitest'

desc 'Run validation test (requires schematron-nokogiri)'
Rake::TestTask.new('test_validation') do |t|
  t.test_files = Dir['HPXMLtoOpenStudio/tests/test_validation.rb']
  t.warning = false
  t.verbose = true
end

desc 'Run all tests (excluding validation test)'
Rake::TestTask.new('test_all') do |t|
  t.test_files = Dir['*/tests/*.rb'] - Dir['HPXMLtoOpenStudio/tests/test_validation.rb']
  t.warning = false
  t.verbose = true
end
