# require "ruby-metrics"

# class Metric

#   module ClassMethods

#     def agent
#       @@agent ||= Metrics::Agent.new
#     end

#     def counter(name)
#       self.agent.counter(name)
#     end

#     def synchronize(name, &block)
#       @@mutex ||= Hash.new
#       @@mutex[name] ||= Mutex.new

#       @@mutex[name].synchronize(&block)
#     end

#   end
#   extend ClassMethods


#   def initialize(type, name, &block)
#     @name   = name
#     @metric = self.class.agent.send(type.to_sym, name, &block)
#   end

#   def method_missing(method_name, *method_args, &method_block)
#     self.class.synchronize(@name) do
#      @metric.send(method_name, *method_args, &method_block)
#     end
#   end

# end
