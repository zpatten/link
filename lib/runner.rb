# frozen_string_literal: true

################################################################################

at_exit do
  $logger.fatal(:at_exit) { 'Shutting down!' }

  stop!
end

################################################################################

def start!(console: false)
  $0 = 'Link Server'
  $logger.info { "Loading Data" }
  Config.load
  ItemType.load
  Storage.load
  create_pid_file(LINK_SERVER_PID_FILE)
  trap_signals

  $logger.info(:main) { "Starting Up" }
  start_threads!

  $logger.info(:main) { "Starting Sinatra" }
  WebServer.run!
  $logger.warn { "Sinatra Stopped"}
end

def stop!
  $logger.info(:main) { "Stopping Threads" }
  stop_threads!

  $logger.info(:main) { "Saving Data" }
  ItemType.save
  Storage.save
end

def trap_signals
  %w( INT TERM QUIT ).each do |signal|
    Signal.trap(signal, 'EXIT')
  end
end

################################################################################

def start_threads!
  start_thread_prometheus
  start_thread_signals
  start_thread_autosave
  start_thread_backup
  Servers.start!(container: false)
end

def stop_threads!
  $origin.resolve
  Servers.stop!(container: false)
  $pool.shutdown
  $pool.wait_for_termination(3)
end

################################################################################

def create_pid_file(pid_file)
  IO.write(pid_file, Process.pid)
end

def read_pid_file(pid_file)
  IO.read(pid_file).strip.to_i
end

def destroy_pid_file(pid_file)
  begin
    FileUtils.rm(pid_file)
  rescue Errno::ENOENT
  end
end

################################################################################

def process_alive?(pid)
  Process.kill(0, pid)
  true

rescue Errno::ESRCH
  false
end

def wait_for_process(pid)
  started_at = Time.now.to_f
  while (Time.now.to_f - started_at) < PID_TIMEOUT do
    return true if !process_alive?(pid)
    sleep 0.25
  end

  false
end

################################################################################

def exception_handler
  begin
    yield
  rescue Exception => e
    $logger.fatal(:main) { e.message.ai }
    $logger.fatal(:main) { e.backtrace.ai }
  end
end

def stop_process(pid_file, name)
  pid = read_pid_file(pid_file)

  return false if pid == 0

  %w( QUIT TERM KILL ).each do |signal|
    begin
      $logger.fatal(:main) { "Attempting to stop #{name} (PID #{pid}) with #{signal}..." }
      Process.kill(signal, pid)
      return true if wait_for_process(pid)

    rescue Errno::ESRCH
      $logger.fatal(:main) { "Process for #{name} not found!" }
      break
    end
  end

  false

rescue Errno::ENOENT
  $logger.fatal(:main) { "PID file for #{name} not found!" }
  false

ensure
  destroy_pid_file(pid_file)
end

################################################################################

if $stop
  stop_process(LINK_SERVER_PID_FILE, 'Link Server')
end

if $start
  if $foreground
    start!
  else
    puts "BG"
    Process.fork do
      Process.daemon(true)
      start!
    end
  end
end
