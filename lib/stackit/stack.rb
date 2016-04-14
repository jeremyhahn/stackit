module Stackit
  class Stack

    attr_accessor :cloudformation
    attr_accessor :stack_id
    attr_accessor :stack_name
    attr_accessor :description
    attr_accessor :parameters
    attr_accessor :creation_time
    attr_accessor :last_updated_time
    attr_accessor :stack_status
    attr_accessor :stack_status_reason
    attr_accessor :disable_rollback
    attr_accessor :timeout_in_minutes
    attr_accessor :stack_policy_body
    attr_accessor :stack_policy_url
    attr_accessor :stack_policy_during_update_body
    attr_accessor :stack_policy_during_update_url
    attr_accessor :on_failure
    attr_accessor :use_previous_template
    attr_accessor :retain_resources

    def initialize(options = {})
      options = options.to_h.symbolize_keys!
      @cloudformation = options[:cloudformation] || Stackit.cloudformation
      @stack_name = options[:stack_name]
      @description = options[:description]
      @parameters = options[:parameters]
      @disable_rollback = options[:disable_rollback]
      @notification_arns = options[:notification_arns]
      @timeout_in_minutes = options[:timeout_in_minutes]
      @capabilities = options[:capabilities]
      @tags = options[:tags]
      @on_failure = options[:on_failure]
      @use_previous_template = options[:use_previous_template] || true
      @retain_resources = options[:retain_resources]
    end

    def [](key)
      parameters[key.to_sym] || outputs[key.to_sym] || resources[key.to_sym]
    end

    def parameters
      @parameters ||= begin
        stack.parameters.inject({}) do |hash, param|
          hash.merge(param[:parameter_key].to_sym => param[:parameter_value])
        end
      rescue ::Aws::CloudFormation::Errors::ValidationError => e
        [] if e.message =~ /Stack with id #{stack_name} does not exist/
      end
    end

    def outputs
      @outputs ||= begin
        stack.outputs.inject({}) do |hash, output|
          hash.merge(output[:output_key].to_sym => output[:output_value])
        end
      rescue ::Aws::CloudFormation::Errors::ValidationError => e
        [] if e.message =~ /Stack with id #{stack_name} does not exist/
      end
    end

    def resources
      @resources ||= list_stack_resources.inject({}) do |hash, resource|
        hash.merge(resource[:logical_resource_id].to_sym => resource[:physical_resource_id])
      end
    end

    def notification_arns
      @notification_arns ||= begin
        stack.notification_arns.inject([]) do |arr, arn|
          arr.push(arn)
        end
      rescue ::Aws::CloudFormation::Errors::ValidationError => e
        [] if e.message =~ /Stack with id #{stack_name} does not exist/
      end
    end

    def capabilities
      @capabilities ||= stack.capabilities.inject([]) do |arr, capability|
        arr.push(capability)
      end
    end

    def tags
      @tags ||= begin
        stack.tags.inject([]) do |arr, tag|
          arr.push(tag)
        end
      rescue ::Aws::CloudFormation::Errors::ValidationError => e
        [] if e.message =~ /Stack with id #{stack_name} does not exist/
      end
    end

    def hydrate!
      @stack_id = stack.stack_id
      @description = stack.description
      @creation_time = stack.creation_time
      @last_updated_time = stack.last_updated_time
      @stack_status = stack.stack_status
      @stack_status_reason = stack.stack_status_reason
      @disable_rollback = stack.disable_rollback
      @timeout_in_minutes = stack.timeout_in_minutes
      @stack_policy_body = stack.stack_policy_body if stack.respond_to?(:stack_policy_body)
      @stack_policy_url = stack.stack_policy_url if stack.respond_to?(:stack_policy_url)
      self
    end

    def create_stack_request_params
      {
        stack_name: stack_name,
        parameters: to_request_parameters,
        disable_rollback: disable_rollback,
        timeout_in_minutes: timeout_in_minutes,
        notification_arns: notification_arns,
        on_failure: on_failure,
        stack_policy_body: stack_policy_body,
        stack_policy_url: stack_policy_url,
        tags: to_request_tags
      }
    end

    def update_stack_request_params
      {
        stack_name: stack_name,
        use_previous_template: use_previous_template,
        stack_policy_during_update_body: stack_policy_during_update_body,
        stack_policy_during_update_url: stack_policy_during_update_url,
        parameters: to_request_parameters,
        stack_policy_body: stack_policy_body,
        stack_policy_url: stack_policy_url,
        tags: to_request_tags
      }
    end

    def delete_stack_request_params
    {
      stack_name: stack_name,
      retain_resources: retain_resources
    }
    end

  private

    def stack
      @stack ||= cloudformation.describe_stacks(
        stack_name: stack_name
      )[:stacks].first
    end

    def list_stack_resources(next_token = nil)
      result = []
      response = cloudformation.list_stack_resources(
        stack_name: stack.stack_id
      ).inject([]) do |arr, page|
        arr.concat(page[:stack_resource_summaries])
      end
    end

    def to_request_parameters(params = parameters)
      params.map do |k, v|
        if v == :use_previous_value
          { 'parameter_key' => k, 'use_previous_value' => true }
        else
          { 'parameter_key' => k, 'parameter_value' => v || '' }
        end
      end
    end

    def to_request_tags(tagz = tags)
      tagz.map do |k, v|
        { 'key' => k, 'value' => v || '' }
      end
    end

  end
end
