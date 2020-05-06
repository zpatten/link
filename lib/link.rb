#!/usr/bin/env ruby
# frozen_string_literal: true

Thread.current.name = 'main'

require 'rubygems'
require 'bundler/setup'

################################################################################

require 'benchmark'
require 'json'
require 'logger'
require 'optparse'
require 'ostruct'
require 'pp'
require 'resolv'
require 'securerandom'
require 'socket'
require 'timeout'
require 'zlib'

################################################################################

require 'awesome_print'
require 'concurrent'


module Link

################################################################################

  GIGAJOULE            = 10 ** 9
  INT_32_MAX           = (2**32).div(2) - 1
  LINK_ROOT            = File.expand_path(File.join(__FILE__, '..', '..'))
  THREAD_TIMEOUT       = 10
  METHOD_PROXY_TIMEOUT = THREAD_TIMEOUT.div(2)
  FUTURE_TIMEOUT       = 60
  PING_TIMEOUT         = 30
  RESPONSE_TIMEOUT     = 60

  PROCESS_TIMEOUT      = 10

################################################################################

  LINK_SERVER_PID_FILE   = File.join(LINK_ROOT, 'link.pid')
  LINK_WATCHDOG_PID_FILE = File.join(LINK_ROOT, 'link-watchdog.pid')

################################################################################

  THREAD_POOL = Concurrent::CachedThreadPool.new(
    auto_terminate: true,
    name: 'link'
  )

  require 'link/cache'
  require 'link/data'
  require 'link/logger'
  require 'link/runner'
  require 'link/support'
  require 'link/web_server'

  # require 'server'
  # require 'servers'
  # require 'support'
  # require 'storage'
  # require 'thread_pool'
  # require 'tasks'

  # require 'web_server'

  # extend Link::Support
  # extend Link::Support::Process
  # extend Link::Tasks

  # Storage.load

################################################################################

  # require 'options'

################################################################################

  # require 'link/config'
  # require 'link/item_type'
  # require 'link/logger'
  # require 'link/runner'
  # require 'link/storage'
  # require 'link/support'

################################################################################

end


# Link::Config.read
# Link::ItemType.read

#   at_exit do
#     $logger.fatal(:at_exit) { 'Shutting down!' }
#     Link.stop
#     # ThreadPool.shutdown!
#     # if master?
#     #   Servers.shutdown!
#     #   ItemType.save
#     #   Storage.save
#     # end
#   end

# Link.trap_signals

# Link::Options.parse(ARGV)
