# frozen_string_literal: true

################################################################################

at_exit do
  LinkLogger.fatal(:at_exit) { 'Shutting down!' }

  stop!
end

################################################################################

def start!(console: false)
  create_pid_file

  $0 = 'Link Server'
  LinkLogger.info(:main) { "Loading Data" }
  trap_signals

  start_threads!

  LinkLogger.info(:main) { "Link Started" }
  if defined?(WebServer)
    WebServer.run!
  else
    sleep 1 while $pool.running?
  end
  LinkLogger.warn(:main) { "Link Stopped" }
end

def stop!
  stop_threads!

  LinkLogger.info(:main) { "Saving Data" }
  ItemTypes.save
  Storage.save
end

def trap_signals
  TRAP_SIGNALS.each do |signal|
    Signal.trap(signal, 'EXIT')
  end
end

################################################################################

def start_threads!
  LinkLogger.info(:main) { "Starting Threads" }
  start_thread_mark
  start_thread_prometheus
  start_thread_signals
  start_thread_autosave
  start_thread_backup
  # Servers.select(&:container_alive?).each { |s| $pool.post { s.start!(container: false) } }
  # Servers.select(&:container_alive?).each { |s| s.start!(container: false) }
  # Servers.select { |s| s.name == 'science' }.each { |s| s.start!(container: true) }
  Servers.all.each { |s| s.start!(container: true) }
  start_thread_watchdog
end

def stop_threads!
  LinkLogger.info(:main) { "Stopping Threads" }
  $origin.resolve
  Servers.stop!(container: false)
  $pool.shutdown
  $pool.wait_for_termination(30)
end

################################################################################

def create_pid_file
  IO.write(PID_FILE, Process.pid)
end

def read_pid_file
  IO.read(PID_FILE).strip.to_i
end

def destroy_pid_file
  begin
    FileUtils.rm(PID_FILE)
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
    return true unless process_alive?(pid)
    sleep 1
  end

  false
end

################################################################################

def stop_process!
  pid = read_pid_file

  LinkLogger.warn(:stop) { "Invalid PID file!" }
  return false if pid == 0

  PID_STOP_SIGNAL_ORDER.each do |signal|
    begin
      LinkLogger.fatal(:stop) { "Attempting to stop server (PID #{pid.ai}) with #{signal.ai}..." }
      Process.kill(signal, pid)
      return true if wait_for_process(pid)

    rescue Errno::ESRCH
      LinkLogger.fatal(:stop) { "Process for server (PID #{pid.ai}) not found!" }
      break
    end
  end

  raise "Failed to stop #{name}! (PID #{pid})"
  false

rescue Errno::ENOENT
  LinkLogger.fatal(:stop) { "PID file not found!" }
  false

ensure
  destroy_pid_file
end

################################################################################

if $stop
  stop_process!
end

if $start
  if $foreground
    LinkLogger.info(:main) { "Starting in foreground" }
    start!
  else
    LinkLogger.info(:main) { "Starting in background" }
    Process.fork do
      Process.daemon(true)
      start!
    end
  end
end
