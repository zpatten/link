module Link
  module Support

################################################################################

    module Extensions

      def deep_clone(object=self)
        Marshal.load(Marshal.dump(object))
      end

    end

    Object.include(Link::Support::Extensions)

################################################################################

  end
end
