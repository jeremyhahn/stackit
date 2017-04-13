require 'thor'

module Stackit

  class ThorNotifier < Thor

    include Thor::Actions

    def initialize(*args)
      super(*args)
    end

    no_commands do

      def backtrace(e)
        puts
        puts e.backtrace
      end

      def error(message, exitstatus = 1)
        say_status 'ERROR', message, :red
        exit exitstatus
      end
  
      def success(message)
        say_status 'OK', message
      end
  
      def response(response, message = 'Success', respond_to_key = 'stack_id')
        if response.is_a?(::Seahorse::Client::Response) || response.is_a?(Stackit::ManagedStack::DRY_RUN_RESPONSE)
          if response.respond_to?(respond_to_key)
            success(response.send(respond_to_key))
          else
            success(message)
          end
        else
          error(response)
        end
      end

    end
  end

  class DefaultNotifier < ThorNotifier; end

end
