module Link
  module Support
    class RescueRetry

################################################################################

      module ClassMethods

        def default_max_attempts
          3
        end

        def default_sleep_for
          3
        end

        def default_rescue_exceptions
          [
            Errno::ECONNABORTED,
            Errno::ECONNREFUSED,
            Errno::ECONNRESET,
            Errno::ENOTSOCK,
            Errno::EPIPE,
            IOError,
            Net::OpenTimeout,
            RuntimeError
          ]
        end

        def attempt(options={}, &block)
          max_attempts      = options.fetch(:max_attempts, default_max_attempts)
          rescue_exceptions = options.fetch(:rescue_exceptions, default_rescue_exceptions)
          sleep_for         = options.fetch(:sleep_for, default_sleep_for)
          on_exception      = options.fetch(:on_exception, nil)

          attempts = 1

          begin
            block.call
          rescue *rescue_exceptions => e

            # calculate how long to sleep for; make sure we at most retry every minute
            # sleep_for = (3 * attempts)
            # sleep_for = attempts**2
            # sleep_for = 60 if sleep_for > 60

            # let the user know what is going on
            logger.fatal { "Exception: #{e.full_message}" }
            logger.fatal { "Sleeping for #{sleep_for} seconds then retrying...  (Attempt #{attempts} of #{max_attempts})" }

            # if we exceed the max attempts throw the exception
            raise e if ((max_attempts != -1) && (attempts > max_attempts))

            # if we have an on_exception callback fire it
            on_exception.nil? or on_exception.call(e)

            # sleep before we try again
            sleep sleep_for

            attempts += 1
            retry
          end
        end

      end
      extend ClassMethods

################################################################################

    end
  end
end
