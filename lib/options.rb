# frozen_string_literal: true

require 'optparse'

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
  thread = ThreadPool.thread("sinatra", priority: -100) do
    WebServer.run! do |server|
      Servers.all.each { |s| s.running? && s.startup! }
    end
  end
end

op.on("--start=NAME", "Start a server") do |name|
  server = Servers.find_by_name(name)
  server.start!
  exit
end

op.on("--stop=NAME", "Stop a server") do |name|
  server = Servers.find_by_name(name)
  server.stop!
  exit
end

op.on("--add=NAME,[TYPE]", "Add a server") do |list|
  name, type = list.split(',')
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
