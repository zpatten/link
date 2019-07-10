require 'optparse'

$options = Hash.new

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("-v", "--[no-]verbose", FalseClass, "Run verbosely") do |v|
    options[:verbose] = v
  end

  opts.on("-h", "--help", "Print this help") do
    puts opts
    exit
  end

  opts.on("-m", "--master", "Run as master") do
    $options[:master] = true
    puts "MASTER!"
  end
end.parse!

p $options
p ARGV

exit
