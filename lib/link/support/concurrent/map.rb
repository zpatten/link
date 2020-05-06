module Link
  module Support
    module Concurrent
      module Map

  ################################################################################

        module ClassMethods

          def [](hash)
            ::Concurrent::Map.new.marshal_load(hash)
          end

        end

  ################################################################################

        def to_h
          self.marshal_dump
        end

        def to_json(options=nil)
          self.to_h.to_json(options)
        end

  ################################################################################

      end
    end
  end
end

Concurrent::Map.extend(Link::Support::Concurrent::Map::ClassMethods)
Concurrent::Map.include(Link::Support::Concurrent::Map)
