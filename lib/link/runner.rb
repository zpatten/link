# frozen_string_literal: true

require 'link/runner/process'

module Link
  class Runner

################################################################################

    module ClassMethods

      @@foreground = false
      @@start      = false
      @@stop       = false
      @@restart    = false
      @@loglevel   = ::Logger::INFO

      def parse(options)
        parser = OptionParser.new do |op|
          op.banner = "Usage: #{$0} [options]"

          op.on("-v", "--[no-]verbose", "Run verbosely") do |v|
            @@loglevel = (v ? ::Logger::DEBUG : ::Logger::INFO)
          end

          op.on("-h", "--help", "Print this help") do
            puts op
            exit
          end

          op.on("--start", "Start the Link") do
            @@start = true
          end

          op.on("--stop", "Stop the Link") do
            @@stop = true
          end

          op.on("--restart", "Restart the Link") do
            @@start = true
            @@stop = true
          end

          op.on('-f', 'Run in foreground') do
            @@foreground = true
          end
        end

        parser.parse!(options.dup)

        self
      end

      def execute(args=ARGV)
        parse(args)

        logger(@@loglevel)

        stop if @@stop
        start(@@foreground) if @@start
      end

    end

    extend ClassMethods

    extend Process

################################################################################

  end
end
