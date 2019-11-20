# frozen_string_literal: true

$start = false
$stop = false
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

def process_alive?(pid)
  Process.kill(0, pid)
  true

rescue Errno::ESRCH
  false
end

def start_link
  Process.fork do
    require_relative '../lib/web_server'
    Process.daemon(true, false)
    Config.load
    Storage.load
    $0 = 'Link Server'
    IO.write('link.pid', Process.pid)
    ThreadPool.execute
  end
end

def start_watchdog(pid)
  Process.fork do
    Process.daemon(true, false)
    $0 = 'Link Watchdog'
    sleep 1
    $logger.info(:watchdog) { "Started" }
    IO.write('link-watchdog.pid', Process.pid)
    loop do
      pid = IO.read('link.pid').to_i
      unless process_alive?(pid)
        start_link
      end
      sleep 1
    end
  end
end

if $stop
  begin
    Process.kill('TERM', IO.read('link-watchdog.pid').to_i)
  rescue Errno::ESRCH, Errno::ENOENT
    puts "Failed to find Link watchdog process!"
  end
  begin
    FileUtils.rm('link-watchdog.pid')
  rescue Errno::ENOENT
  end

  begin
    Process.kill('INT', IO.read('link.pid').to_i)
  rescue Errno::ESRCH, Errno::ENOENT
    puts "Failed to find Link process!"
  end
  begin
    FileUtils.rm('link.pid')
  rescue Errno::ENOENT
  end
end

if $start
  pid = start_link
  start_watchdog(pid)
end
