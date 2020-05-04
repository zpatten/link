# frozen_string_literal: true

$start = false
$stop = false
$foreground = false
require 'optparse'

parser = OptionParser.new do |op|
  op.banner = "Usage: #{$0} [options]"

  op.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    $logger.level = (v ? Logger::DEBUG : Logger::INFO)
  end

  op.on("-h", "--help", "Print this help") do
    puts op
    exit
  end

  # op.on("-m", "--master", "Run as master") do
  #   thread = ThreadPool.thread("sinatra", priority: -100) do
  #     WebServer.run! do |server|
  #       Servers.all.each { |s| s.running? && s.start_rcon! }
  #     end
  #   end
  # end

  op.on("--start", "Start the Link") do
    $start = true
  end

  op.on("--stop", "Stop the Link") do
    $stop = true
  end

  op.on("--restart", "Restart the Link") do
    $start = true
    $stop = true
  end

  op.on('-f', 'Run in foreground') do
    $foreground = true
  end

  # op.on("--start=NAME", "Start a server") do |name|
  #   server = Servers.find_by_name(name)
  #   server.start!
  #   exit
  # end

  # op.on("--stop=NAME", "Stop a server") do |name|
  #   server = Servers.find_by_name(name)
  #   server.stop!
  #   exit
  # end

  # op.on("--add=NAME,[TYPE]", "Add a server") do |list|
  #   name, type = list.split(',')
  #   params = {
  #     name: name,
  #     type: type
  #   }
  #   Servers.create(params)
  #   exit
  # end

  # op.on("--remove=NAME", "Remove a server") do |name|
  #   params = {
  #     name: name
  #   }
  #   Servers.destroy(params)
  #   exit
  # end
end

parser.parse!(ARGV.dup)

def start_link
  if $foreground
    execute
  else
    Process.fork do
      Process.daemon(true)
      execute
    end
  end
end

def start_watchdog(pid)
  Process.fork do
    Process.daemon(true, false)
    $0 = 'Link Watchdog'
    sleep 1
    $logger.info(:watchdog) { "Started" }
    create_pid_file(LINK_WATCHDOG_PID_FILE)
    loop do
      pid = read_pid_file(LINK_SERVER_PID_FILE)
      unless process_alive?(pid)
        start_link
      end
      sleep 1
    end
  end
end

if $stop
  stop_process(LINK_WATCHDOG_PID_FILE, 'Link Watchdog')
  stop_process(LINK_SERVER_PID_FILE, 'Link Server')
end

if $start
  pid = start_link
  start_watchdog(pid)
end
