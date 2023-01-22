# frozen_string_literal: true

################################################################################

at_exit do
  $logger.fatal(:at_exit) { 'Shutting down!' }
  $origin.resolve
  ThreadPool.shutdown!
  if master?
    Servers.shutdown!
    ItemType.save
    Storage.save
  end
end

def trap_signals
  %w( INT TERM QUIT ).each do |signal|
    Signal.trap(signal, 'EXIT')
  end
end

################################################################################

def master?
  Process.pid == master_pid
rescue Errno::ENOENT
  false
end

def master_pid
  read_pid_file(LINK_SERVER_PID_FILE)
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

def execute
  $0 = 'Link Server'
  Config.load
  Storage.load
  create_pid_file(LINK_SERVER_PID_FILE)
  ThreadPool.execute
end

################################################################################
