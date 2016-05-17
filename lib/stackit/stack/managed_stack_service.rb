module Stackit

  class ManagedStackService

    attr_accessor :options
    attr_accessor :stacks

    def initialize(options)
      self.options = options
    end

    def create!
      final_stack.create!
    end

    def update!
      final_stack.update!
    end

    def delete!
      final_stack.delete!
    end

  protected

    def stack_name
      options[:stack_name] || "#{Stackit.environment}-#{options[:stack_name]}"
    end

    def template
      options[:template] || File.expand_path("#{options[:stack_name]}.json", template_dir)
    end

    def stack_policy
      options[:template]
    end

    def stack_policy_during_update
      options[:stack_policy_during_update]
    end

    def parameters_file
      return options[:parameters_file] ||
        File.expand_path("#{options[:stack_name]}.parameters", template_dir)
    end

    def depends
      options[:depends]
    end

    def parameter_mappings
      {}
    end

    def user_defined_parameters
      {}
    end

    def template_dir
      dir = options[:template_dir] ? options[:template_dir] : __dir__
    end

    def disable_rollback
      !!options[:debug] ? true : !!options[:disable_rollback]
    end

    def wait
      options[:wait]
    end

    def force
      options[:force]
    end

    def dry_run
       options[:dry_run]
    end

    def debug
      !!options[:debug]
    end

    def timeout_in_minutes
      options[:timeout_in_minutes]
    end

    def notification_arns
      options[:notification_arns]
    end

    def capabilities
      options[:capabilities]
    end

    def tags
      options[:tags]
    end

    def on_failure
      options[:on_failure]
    end

    def retain_resources
      options[:retain_resources]
    end

    def use_previous_template
      options[:use_previous_template]
    end

    def stack
      @stack ||= ManagedStack.new(
        template: template,
        stack_name: stack_name,
        stack_policy: stack_policy,
        stack_policy_during_update: stack_policy_during_update,
        depends: depends,
        parameters_file: parameters_file,
        parameter_map: parameter_mappings,
        disable_rollback: disable_rollback,
        wait: wait,
        force: force,
        dry_run: dry_run,
        debug: debug,
        timeout_in_minutes: timeout_in_minutes,
        notification_arns: notification_arns,
        capabilities: capabilities,
        tags: tags,
        on_failure: on_failure,
        use_previous_template: use_previous_template,
        retain_resources: retain_resources
      )
    end

    def depends_stacks
      return @depends_stacks unless @depends_stacks.nil?
      @depends_stacks = []
      return @depends_stacks unless options[:depends]
      options[:depends].each do |stack|
        @depends_stacks << Stackit::Stack.new(stack_name: stack)
      end
      @depends_stacks
    end

    def stacks
      @stacks ||= [stack].concat(depends_stacks)
    end

    def resolve_parameter(key)
      Stackit::ParameterResolver.new(depends_stacks).resolve(key)
    end

    def resolve_parameters(keys)
      Stackit::ParameterResolver.new(depends_stacks).resolve(keys)
    end

  private

    def final_stack
      params = user_defined_parameters
      params.merge!(options[:parameters]) if options[:parameters]
      stack.instance_variable_set(:@user_defined_parameters, user_defined_parameters)
      stack
    end

  end
end
