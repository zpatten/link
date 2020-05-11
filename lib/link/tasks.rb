# frozen_string_literal: true

require 'link/tasks/base'

require 'link/tasks/auto_save'
require 'link/tasks/prometheus'

module Link

################################################################################

  class Tasks

    module ClassMethods

      def start!
        klasses.map(&:start!)
      end

      def stop!
        klasses.map(&:stop!)
      end

    private

      def excluded_klasses
        [ Link::Tasks::Base ]
      end

      def klasses
        (Link::Tasks.constants.map(&Link::Tasks.method(:const_get)).grep(Class) - excluded_klasses).sort { |a,b| a.to_s <=> b.to_s }
      end

    end
    extend ClassMethods

  end

################################################################################

end
