# frozen_string_literal: true

# Load helper file and sampling file
resources_dir = File.join(File.dirname(__FILE__), '../resources')
require File.join(resources_dir, 'buildstock')
require 'optparse'
require 'csv'
require_relative 'integrity_checks'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename(__FILE__)} -o outfile -l lookup_file\n e.g., #{File.basename(__FILE__)} -o /path/to/buildstock.csv -l /path/to/options_lookup.tsv"
  opts.banner += "\nThe appropriate options_lookup.tsv to check against is the one that will be used in the ResStock analysis."

  opts.on('-o', '--output <STRING>', 'Output file name') do |t|
    options[:outfile] = t
  end

  opts.on('-l', '--lookup_file <STRING>', 'Lookup file name') do |t|
    options[:lookup_file] = t
  end

  opts.on_tail('-h', '--help', 'Display help') do
    puts opts
    exit!
  end
end.parse!

if (not options[:outfile]) || (not options[:lookup_file])
  fail "ERROR: All 2 arguments are required. Call #{File.basename(__FILE__)} -h for usage."
end

outfile = options[:outfile]
lookup_file = options[:lookup_file]

t0 = Time.now
begin
  check_buildstock(outfile, lookup_file)
rescue Exception => e
  puts e.message
else
  puts "Checking took: #{((Time.now - t0) / 60.0).round(1)} minutes."
end
