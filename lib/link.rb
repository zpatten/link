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

require 'active_support/core_ext/class/attribute'
require 'active_support/inflector'
require 'awesome_print'
require 'concurrent'
require 'concurrent-edge'

################################################################################

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

  require 'link/cache'
  require 'link/data'
  require 'link/factorio'
  require 'link/logger'
  require 'link/runner'
  require 'link/support'
  require 'link/tasks'
  require 'link/web_server'

################################################################################

end
