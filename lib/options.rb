require 'optparse'

$options = Hash.new

op = OptionParser.new
op.banner = "Usage: #{$0} [options]"

op.on("-v", "--[no-]verbose", "Run verbosely") do |v|
  $options[:verbose] = v
end

op.on("-h", "--help", "Print this help") do
  puts opts
  exit
end

op.on("-m", "--master", "Run as master") do
  $options[:master] = true
  puts "MASTER!"
end

op.parse!

p $options
p ARGV
