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

lookup_csv_data = CSV.open(options[:lookup_file], col_sep: "\t").each.to_a

t0 = Time.now
check_buildstock(options[:outfile], lookup_csv_data, options[:lookup_file])
t1 = Time.now

puts "Checking took: #{((t1 - t0) / 60.0).round(1)} minutes."
