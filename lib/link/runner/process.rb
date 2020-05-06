# frozen_string_literal: true

module Link
  class Runner
    module Process

################################################################################

      def master?
        ::Process.pid == master_pid
      rescue Errno::ENOENT
        false
      end

      def master_pid
        read_pid_file(LINK_SERVER_PID_FILE)
      end

################################################################################

      def write_pid_file(pid_file)
        pid = ::Process.pid
        logger.debug { "Write PID #{pid.inspect} to #{pid_file.inspect}" }
        IO.write(pid_file, pid)
        pid
      end

      def read_pid_file(pid_file)
        pid = IO.read(pid_file).strip.to_i
        logger.debug { "Read PID #{pid.inspect} from #{pid_file.inspect}" }
        pid
      end

      def remove_pid_file(pid_file)
        begin
          logger.debug { "Remove PID file #{pid_file.inspect}" }
          FileUtils.rm(pid_file)
        rescue Errno::ENOENT
        end
      end

################################################################################

      def process_alive?(pid)
        ::Process.kill(0, pid)
        true

      rescue Errno::ESRCH
        false
      end

      def wait_for_process(pid)
        started_at = Time.now.to_f
        while (Time.now.to_f - started_at) < PROCESS_TIMEOUT do
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
            logger.fatal { "Attempting to stop #{name} (PID #{pid}) with #{signal}..." }
            puts "Attempting to stop #{name} (PID #{pid}) with #{signal}..."
            ::Process.kill(signal, pid)
            return true if wait_for_process(pid)

          rescue Errno::ESRCH
            logger.fatal { "Process for #{name} not found!" }
            break
          end
        end

        false

      rescue Errno::ENOENT
        logger.fatal { "PID file for #{name} not found!" }
        false

      ensure
        remove_pid_file(pid_file)
      end

################################################################################

      def start(foreground=false)
        logger.info { "Starting Link" }
        if foreground
          start_link
        else
          start_watchdog
        end
      end

      def stop
        logger.fatal { "Stopping Link" }
        if master?
          Link::WebServer.stop!
          THREAD_POOL.shutdown
          THREAD_POOL.wait_for_termination(PROCESS_TIMEOUT)

          Link::Data.write

          # Link::Config.write
          # Link::ItemType.write
          # Link::Storage.write

          # ThreadPool.shutdown!
          # if master?
          #   Servers.shutdown!
          #   ItemType.save
          #   Storage.save
          # end
        else
          stop_process(LINK_WATCHDOG_PID_FILE, 'Link Watchdog')
          stop_process(LINK_SERVER_PID_FILE, 'Link Server')
        end
      end

################################################################################

      def start_watchdog
        ::Process.fork do
          ::Process.daemon(true)
          $0 = 'Link Watchdog'
          write_pid_file(LINK_WATCHDOG_PID_FILE)

          logger.info { "Starting Watchdog..." }
          loop do
            ::Process.fork do
              ::Process.daemon(true)
              start_link
            end
            sleep 3

            pid = read_pid_file(LINK_SERVER_PID_FILE)
            sleep 1 while process_alive?(pid)

            logger.fatal { "Watchdog restarting Link" }
          end
        end
      end

      def start_link
        at_exit do
          logger.fatal { "Shutting down!" }
          Link::Runner.stop
        end

        $0 = 'Link Server'
        write_pid_file(LINK_SERVER_PID_FILE)

        Link::Data.read

        # THREAD_POOL.post do
        #   Link::WebServer.run!
        #   logger.fatal { "Web Server Stopped!" }
        # end
        # logger.info { "After WebServer Block" }
        # Thread.pass while true

        # THREAD_POOL.wait_for_termination
        # sleep 1 while true
        # start everything
        # sleep 1 while THREAD_POOL.running?
        # logger.fatal { "Thread Pool Stopped!" }
        # Thread.current.join

        Link::WebServer.run!
      end

################################################################################

    end
  end
end

