# frozen_string_literal: true

# This file is only used to run all tests and collect results on the CI.
# All rake tasks have been moved to tasks.rb.

require 'rake'
require 'rake/testtask'
require 'ci/reporter/rake/minitest'

desc 'Perform tasks related to unit tests'
namespace :test do
  desc 'Run integrity checks for all projects'
  Rake::TestTask.new('integrity_checks') do |t|
    t.libs << 'test'
    t.test_files = Dir['project_*/tests/*.rb']
    t.warning = false
    t.verbose = true
  end

  desc 'Run all integrity check unit tests'
  Rake::TestTask.new('unit_tests') do |t|
    t.libs << 'test'
    t.test_files = Dir['test/test_integrity_checks.rb'] + Dir['measures/*/tests/*.rb']
    t.warning = false
    t.verbose = true
  end

  desc 'Run measures osw test for a sampled datapoint'
  Rake::TestTask.new('measures_osw') do |t|
    t.libs << 'test'
    t.test_files = Dir['test/test_measures_osw.rb']
    t.warning = false
    t.verbose = true
  end

  desc 'Run regression tests for all example osws'
  Rake::TestTask.new('regression_tests') do |t|
    t.libs << 'test'
    t.test_files = Dir['workflows/tests/*.rb']
    t.warning = false
    t.verbose = true
  end
end
