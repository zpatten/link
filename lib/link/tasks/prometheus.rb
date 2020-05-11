# frozen_string_literal: true

module Link
  class Tasks

################################################################################

    class Prometheus < Base

      def self.task
        Link::Support::Metrics.push
      end

    end

################################################################################

  end
end
