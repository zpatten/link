# frozen_string_literal: true

require 'optparse'

################################################################################

class Runner

  attr_reader :pool, :cancellation, :origin

################################################################################

  def initialize
    @options = Hash.new
    @parser  = OptionParser.new do |op|
      op.banner = "Usage: #{$0} [options]"

      op.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        LinkLogger.level = (v ? Logger::DEBUG : Logger::INFO)
      end

      op.on("-h", "--help", "Print this help") do
        puts op
        exit!
      end

      op.on("--start", "Start the Link") do
        @options[:start] = true
      end

      op.on("--stop", "Stop the Link") do
        @options[:stop] = true
      end

      op.on("--restart", "Restart the Link") do
        @options[:start] = true
        @options[:stop]  = true
      end

      op.on('-f', 'Run in foreground') do
        @options[:foreground] = true
      end

      op.on('-c', '--console', 'Run Console') do
        @options[:console] = true
      end
    end
  end

################################################################################

  def run!
    @parser.parse!(ARGV.dup)

    if @options[:console]
      require 'pry'
      binding.pry
      exit!
    end

    require_relative 'web_server'

    if @options[:stop]
      stop_process!
    end

    if @options[:start]

      if @options[:foreground]
        LinkLogger.info(:runner) { "Starting in foreground" }
        start!
      else
        LinkLogger.info(:runner) { "Starting in background" }
        Process.fork do
          Process.daemon(true)
          start!
        end
      end
    end
  end

################################################################################

  def trap_signals
    at_exit do
      LinkLogger.fatal(:at_exit) { 'Shutting down!' }
      Runner.stop!
    end

    TRAP_SIGNALS.each do |signal|
      Signal.trap(signal, 'EXIT')
    end
  end

################################################################################

  def start!(console: false)
    create_pid_file
    trap_signals

    Metrics::Prometheus.configure!

    LinkLogger.info(:runner) { "Starting" }

    start_pool!
    start_tasks!
    start_servers!

    LinkLogger.info(:runner) { "Link Started" }
    if defined?(WebServer)
      WebServer.run!
    else
      sleep 1 while Runner.pool.running?
    end
    LinkLogger.warn(:runner) { "Link Stopped" }
  end

  def stop!
    LinkLogger.info(:runner) { "Stopping" }

    stop_servers!
    stop_tasks!
    stop_pool!

    Factorio::ItemTypes.save
    Factorio::Storage.save
  end

################################################################################

  def start_servers!
    LinkLogger.info(:runner) { "Starting Servers" }
    Servers.select(&:container_alive?).each { |s| @pool.post { s.start! } }
  end

  def stop_servers!
    LinkLogger.info(:runner) { "Stopping Servers" }
    Servers.stop!(container: false)
  end

################################################################################

  def start_tasks!
    LinkLogger.info(:runner) { "Starting Threads" }
    schedule_task_mark
    schedule_task_prometheus
    schedule_task_trim
    schedule_task_backup
    schedule_task_signals
    schedule_task_watchdog
  end

  def stop_tasks!
    LinkLogger.info(:runner) { "Stopping Threads" }
    @origin and (@origin.resolved? or @origin.resolve)
    sleep (Config.value(:timeout, :thread) + 1)
  end

################################################################################

  def start_pool!
    @pool = THREAD_EXECUTOR.new(
      name: 'link',
      auto_terminate: false,
      min_threads: 2,
      max_threads: [2, Concurrent.processor_count].max,
      max_queue: [2, Concurrent.processor_count * 5].max,
      fallback_policy: :abort
    )
    @cancellation, @origin = Concurrent::Cancellation.new
  end

  def stop_pool!
    @pool.shutdown

    # puts "@pool.running?=#{@pool.running?.ai}"
    # puts ("-" * 80)
    # threads = Thread.list.sort_by { |t| t.name || '-' }
    # puts "Threads Running: #{threads.count}"
    # threads.each { |t| puts "thread:#{t.name || '-'}" }
    # while @pool.running? do
    #   puts ("-" * 80)
    #   threads = Thread.list.sort_by { |t| t.name || '-' }
    #   puts "Threads Running: #{threads.count}"
    #   threads.each { |t| puts "thread:#{t.name || '-'}" }
    #   sleep 1
    # end

    @pool.wait_for_termination(Config.value(:timeout, :pool))
    puts Thread.list.count.ai
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

  module ClassMethods
    @@runner ||= Runner.new
    @@runner_public_methods ||= @@runner.public_methods

    def method_missing(method_name, *args, &block)
      if @@runner_public_methods.include?(method_name)
        @@runner.send(method_name, *args, &block)
      else
        super
      end
    end

    def respond_to?(method_name, include_private=false)
      @@runner_public_methods.include?(method_name) || super
    end

    def respond_to_missing?(method_name, include_private=false)
      @@runner_public_methods.include?(method_name) || super
    end
  end

  extend ClassMethods

################################################################################

end
