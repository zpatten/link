# frozen_string_literal: true

require 'link/data/config'
require 'link/data/item_type'
require 'link/data/storage'

module Link
  class Data

################################################################################

    module ClassMethods

      def klasses
        Link::Data.constants.map(&Link::Data.method(:const_get)).grep(Class).sort { |a,b| a.to_s <=> b.to_s }
      end

      def read
        klasses.map(&:read)
      end

      def write
        klasses.map(&:write)
      end

    end

    extend ClassMethods

################################################################################

  end
end
