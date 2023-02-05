# frozen_string_literal: true

class Servers
  module State

################################################################################

    def available
      select { |s| s.available? }
    end

    def unavailable
      select { |s| s.unavailable? }
    end

    def available?
      map(&:available?).any?(true)
    end

    def unavailable?
      !available?
    end

################################################################################

  end
end
