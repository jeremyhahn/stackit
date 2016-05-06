module Stackit

  class ManagedStackService

    attr_accessor :options
    attr_accessor :stacks

    def initialize(options)
      self.options = options
    end

    def create!
      stack.create!
    end

    def update!
      stack.update!
    end

    def delete!
      stack.delete!
    end

  protected

    def stack_name
      return options[:stack_name] ||  
        "#{Stackit.environment}-#{options[:stack_name]}"
    end

    def template
      return options[:template] ||
        File.expand_path("#{options[:stack_name]}.json", template_dir)
    end

    def parameters_file
      return options[:parameters_file] ||
        File.expand_path("#{options[:stack_name]}.parameters", template_dir)
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
      true
    end

    def stack
      params = user_defined_parameters
      params.merge!(options[:parameters]) if options[:parameters]
      ManagedStack.new(
        template: template,
        stack_name: stack_name,
        stack_policy: options[:stack_policy],
        stack_policy_during_update: options[:stack_policy_during_update],
        depends: options[:depends],
        user_defined_parameters: params,
        parameters_file: parameters_file,
        parameter_map: parameter_mappings,
        disable_rollback: !!options[:debug] ? true : (!!options[:disable_rollback] || disable_rollback),
        wait: options[:wait],
        force: options[:force],
        dry_run: options[:dry_run],
        debug: !!options[:debug],
        timeout_in_minutes: options[:timeout_in_minutes],
        notification_arns: options[:notification_arns],
        capabilities: options[:capabilities],
        tags: options[:tags],
        on_failure: options[:on_failure],
        use_previous_template: options[:use_previous_template],
        retain_resources: options[:retain_resources]
      )
    end

    def depends_stacks
      stacks = []
      return stacks unless options[:depends]
      options[:depends].each do |stack|
        stacks << Stackit::Stack.new(stack_name: stack)
      end
      stacks
    end

    def stacks
      @stacks ||= [stack].concat(depends_stacks)
    end

    def resolve_parameter(key)
      depends_stacks.each do |s|
        value = s[key]
        return value unless value.nil?
      end
    end

    def resolve_parameters(keys)
      values = []
      depends_stacks.each do |s|
        keys.each do |key|
          value = s[key]
          values << value unless value.nil?
        end
      end
      values.join(',')
    end

    def opsworks_service_role_arn(key = :OpsWorksServiceRole)
      "arn:aws:iam::#{Stackit.aws.account_id}:role/#{resolve_parameter(key)}"
    end

    def opsworks_cookbook_source(key = :DevOpsBucket)
      "https://s3.amazonaws.com/#{resolve_parameter(key)}/cookbooks.tar.gz"
    end

  end
end
