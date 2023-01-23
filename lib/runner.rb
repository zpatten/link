# frozen_string_literal: true

# def start_link
#   if $foreground
#     create_pid_file(LINK_WATCHDOG_PID_FILE)
#     execute
#   else
#     Process.fork do
#       Process.daemon(true)
#       create_pid_file(LINK_WATCHDOG_PID_FILE)
#       execute
#     end
#   end
# end

# def start_watchdog(pid)
#   Process.fork do
#     Process.daemon(true, false)
#     $0 = 'Link Watchdog'
#     sleep 1
#     $logger.info(:watchdog) { "Started" }
#     create_pid_file(LINK_WATCHDOG_PID_FILE)
#     loop do
#       pid = read_pid_file(LINK_SERVER_PID_FILE)
#       unless process_alive?(pid)
#         start_link
#       end
#       sleep 1
#     end
#   end
# end

if $stop
  # stop_process(LINK_WATCHDOG_PID_FILE, 'Link Watchdog')
  stop_process(LINK_SERVER_PID_FILE, 'Link Server')
end

if $start
  puts "START"
  if $foreground
    puts "FORE"
    execute
  else
    puts "BG"
    Process.fork do
      Process.daemon(true)
      execute
    end
  end
  # pid = start_link
  # start_watchdog(pid)
end

puts "RUNNER START"
