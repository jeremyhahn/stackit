module Stackit

  class WaitError < StandardError; end

  module Wait

    def wait_until_stack_has_key(key)
      Stackit.logger.debug "Waiting until stack #{stack_name} has key #{key}..."
      wait_for(timeout: 15.minutes) do
        stack = Stack.new(stack_name: stack_name).hydrate!
        raise "Stack failure: #{stack.stack_status}" if stack.stack_status =~ /FAILED/
        if stack[key]
          yield stack if block_given?
          true
        end
      end
    end

    def wait_for_stack(status_pattern = /COMPLETE/)
      Stackit.logger.debug "Waiting for stack #{stack_name} to complete..."
      wait_for(timeout: 15.minutes) do
        stack = Stack.new(stack_name: stack_name).hydrate!
        case stack.stack_status
        when /FAILED/
          raise WaitError, "Stack failed during wait: #{stack_name}"
        when status_pattern
          yield stack if block_given?
          true
        else
          false
        end
      end
    end

    def wait_for_stack_to_delete
      Stackit.logger.debug "Waiting for stack #{stack_name} to delete..."
      wait_for(timeout: 15.minutes) do
        begin
          stack = Stack.new(stack_name: stack_name).hydrate!
          if stack.nil?
            yield stack if block_given?
            true
          else
            false
          end
        rescue Aws::CloudFormation::Errors::ValidationError => e
          if e.message.include?("does not exist")
            true
          end
        end
      end
    end

  protected

    def wait_for(opts={})
      raise ArgumentError, 'block expected' unless block_given?
      timeout = opts[:timeout] || 600
      interval = opts[:interval] || 10
      attempts = timeout / interval
      Stackit.logger.debug "Timeout: #{timeout}"
      Stackit.logger.debug "Attempts: #{attempts}"
      actual_attempts = attempts.times do
        break if yield
        sleep interval
      end
      actual_attempts != attempts
    end

  end
end
