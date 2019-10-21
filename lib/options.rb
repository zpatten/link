require 'optparse'

$options = Hash.new

op = OptionParser.new
op.banner = "Usage: #{$0} [options]"

op.on("-v", "--[no-]verbose", "Run verbosely") do |v|
  $logger.level = (v ? Logger::DEBUG : Logger::INFO)
end

op.on("-h", "--help", "Print this help") do
  puts op
  exit
end

op.on("-m", "--master", "Run as master") do
  ThreadPool.thread("sinatra") do
    WebServer.run!
    exit
  end
end

op.on("--start=NAME", "Start a server") do |name|
  $logger.close
  server = Servers.find_by_name(name)
  server.start!
  exit
end

op.on("--add=NAME,[TYPE]", "Add a server") do |list|
  name, type = list.split(',')
  $options[:add] = true
  params = {
    name: name,
    type: type
  }
  Servers.create(params)
  exit
end

op.on("--remove=NAME", "Remove a server") do |name|
  params = {
    name: name
  }
  Servers.destroy(params)
  exit
end

op.parse!

# p $options
# p ARGV
