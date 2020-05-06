# frozen_string_literal: true

class Link
  class Options

    @@foreground = false
    @@start      = false
    @@stop       = false
    @@restart    = false

    def self.start
      Link.start(@@foreground)
    end

    def self.stop
      Link.stop
    end

    def self.restart
      stop
      start
    end

    def self.parse(options=ARGV)
      parser = OptionParser.new do |op|
        op.banner = "Usage: #{$0} [options]"

        op.on("-v", "--[no-]verbose", "Run verbosely") do |v|
          $logger.level = (v ? Logger::DEBUG : Logger::INFO)
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
          @@restart = true
        end

        op.on('-f', 'Run in foreground') do
          @@foreground = true
        end
      end

      parser.parse!(options.dup)

      start if @@start
      stop if @@stop
      restart if @@restart

      options
    end

  end
end
