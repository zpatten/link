# frozen_string_literal: true

module Link
  class Tasks

################################################################################

    class AutoSave < Base

      def self.task
        Link::Data.write
      end

    end

################################################################################

  end
end
