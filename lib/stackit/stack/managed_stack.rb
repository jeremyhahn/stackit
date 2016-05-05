module Stackit
  class ManagedStack < Stack

    include Wait

    attr_accessor :template
    attr_accessor :template_path
    attr_accessor :file_parameters
    attr_accessor :user_defined_parameters
    attr_accessor :parameter_map
    attr_accessor :dry_run
    attr_accessor :depends
    attr_accessor :debug
    attr_accessor :force
    attr_accessor :wait
    attr_accessor :notifier

    def initialize(options={})
      super(options)
      self.template_path = options[:template]
      self.user_defined_parameters = symbolized_user_defined_parameters(options[:user_defined_parameters])
      self.parameter_map = symbolized_parameter_map(options[:parameter_map])
      self.stack_name = options[:stack_name] || default_stack_name
      self.depends = options[:depends] || []
      self.disable_rollback = self.debug ? true : !!options[:disable_rollback]
      self.debug = !!options[:debug] || Stackit.debug
      self.force = options[:force]
      self.wait = options[:wait]
      self.dry_run = options[:dry_run]
      self.notifier = options[:notifier] || Stackit::ThorNotifier.new
      parse_file_parameters(options[:parameters_file]) if options[:parameters_file]
      create_stack_policy(options[:stack_policy])
      create_stack_policy_during_update(options[:stack_policy_during_update])
    end

    def create!
      begin
        response = cloudformation_request(:create_stack)
        notifier.response(response)
      rescue ::Aws::CloudFormation::Errors::AlreadyExistsException => e
        notifier.backtrace(e) if Stackit.debug
        notifier.error(e.message)
      rescue ::Aws::CloudFormation::Errors::ValidationError => e
        notifier.backtrace(e) if Stackit.debug
        notifier.error(e.message)
      end
      response
    end

    def update!
      begin
        response = cloudformation_request(:update_stack)
        notifier.response(response)
      rescue ::Aws::CloudFormation::Errors::AlreadyExistsException => e
        notifier.backtrace(e) if Stackit.debug
        notifier.error(e.message)
      rescue ::Aws::CloudFormation::Errors::ValidationError => e
        if e.message =~ /No updates are to be performed./
          notifier.success(e.message)
        else
          notifier.backtrace(e) if Stackit.debug
          notifier.error(e.message)
        end
      end
      response
    end

    def delete!
      begin
        response = cloudformation_request(:delete_stack)
        notifier.response(response)
      rescue ::Aws::CloudFormation::Errors::AlreadyExistsException => e
        notifier.backtrace(e) if Stackit.debug
        notifier.error(e.message)
      rescue ::Aws::CloudFormation::Errors::ValidationError => e
        notifier.backtrace(e) if Stackit.debug
        notifier.error(e.message)
      end
      response
    end

    def deploy!
      if !File.exist?(template)
        delete!
        wait_for_stack_to_delete
        notifier.success('Delete successful')
      elsif exist?
        begin
          update!
          wait_for_stack
          notifier.success('Update successful')
        rescue ::Aws::CloudFormation::Errors::ValidationError => e 
          if e.message.include? "No updates are to be performed"
            Stackit.logger.info "No updates are to be performed"
          elsif e.message.include? "_FAILED state and can not be updated"
            Stackit.logger.info 'Stack is in a failed state and can\'t be updated. Deleting/creating a new stack.'
            delete!
            wait_for_stack_to_delete
            create!
            wait_for_stack
            notifier.success('Stack deleted and re-created')
          else
            raise e
          end
        end
      else
        begin
          create!
          wait_for_stack
          notifier.success('Created successfully')
        rescue ::Aws::CloudFormation::Errors::ValidationError => e 
          if e.message.include? "_FAILED state and can not be updated"
            Stackit.logger.info 'Stack already exists, is in a failed state, and can\'t be updated. Deleting and creating a new stack.'
            delete!
            wait_for_stack_to_delete
            create!
            wait_for_stack
            notifier.success('Stack deleted and re-created')
          else
            raise e
          end
        end
      end
    end

    def exist?
      describe != nil
    end

    def describe
      response = cloudformation_request(:describe_stacks)
      if response && response[:stacks]
        response[:stacks].first
      else
        nil
      end
    rescue ::Aws::CloudFormation::Errors::ValidationError
      nil
    end

  private

    DRY_RUN_RESPONSE = Struct.new(:stack_id)
    REDACTED_TEXT = '****redacted****'

    def symbolized_user_defined_parameters(params)
      if params
        params.symbolize_keys!
      else
        {}
      end
    end

    def symbolized_parameter_map(param_map)
      if param_map
        param_map.symbolize_keys!
      else
        {}
      end
    end

    def default_stack_name
      self.class.name.demodulize
    end

    def create_template(t, action)
      template_path = t ? t : File.join(Dir.pwd, 'cloudformation', "#{stack_name.underscore.dasherize}.json")
      if !File.exist?(template_path)
        return if action == :delete_stack
        raise "Unable to locate template: #{template_path}"
      end
      template = Template.new(
        :cloudformation => cloudformation,
        :template_path => template_path
      )
      template.parse!
    end

    def create_stack_policy(f)
      policy_path = f ? f : File.join(Stackit.home, 'stackit', 'stack', 'default-stack-policy.json')
      if policy_path =~ /^http/
        self.stack_policy_url = policy_path
      else
        raise "Unable to locate policy: #{policy_path}" unless File.exist?(policy_path)
        self.stack_policy_body = File.read(policy_path)
      end
    end

    def create_stack_policy_during_update(f)
      policy_path = f ? f : File.join(Dir.pwd, "#{stack_name}-update-policy.json")
      if !File.exist?(policy_path)
        Stackit.logger.warn "Unable to locate stack policy during update file: #{policy_path}"
        return
      end
      if policy_path =~ /^http/
        self.stack_policy_during_update_url = policy_path
      else
        raise "Unable to locate update policy: #{policy_path}" unless File.exist?(policy_path)
        self.stack_policy_during_update_body = File.read(policy_path)
      end
    end

    def parse_file_parameters(parameters_file)
      if File.exist?(parameters_file)
        Stackit.logger.info "Parsing cloudformation parameters file: #{parameters_file}"
        @file_parameters = {}
        file_params = JSON.parse(File.read(parameters_file))
        file_params.inject(@file_parameters) do |hash, param|
          hash.merge!(param['ParameterKey'].to_sym => param['ParameterValue'])
        end
      end
    end

    def capabilities
      template.needs_iam_capability? ? ['CAPABILITY_IAM'] : []
    end

    def cloudformation_request(action)
      Stackit.logger.debug "ManagedStack CloudFormation API request: #{action}"
      self.template = create_template(template_path, action);
      cloudformation_options = create_cloudformation_options(action)
      if debug
        Stackit.logger.debug "#{action} request parameters: "
        opts = cloudformation_options.clone
        if opts[:parameters]
          opts[:parameters].each do |param|
            key = param['parameter_key']
            param['parameter_value'] = REDACTED_TEXT if key =~ /username|password/i && !debug
          end
        end
        opts[:template_body] = REDACTED_TEXT if opts[:template_body]
        opts[:stack_policy_body] = JSON.parse(opts[:stack_policy_body]) if opts[:stack_policy_body]
        opts[:stack_policy_during_update_body] = 
          JSON.parse(opts[:stack_policy_during_update_body]) if opts[:stack_policy_during_update_body]
        pp opts
      end
      response = dry_run ? dry_run_response : cloudformation.send(action, cloudformation_options)
      wait_for_stack if wait
      response
    end

    def create_cloudformation_options(action)
      case action
      when :create_stack
        create_stack_request_params.merge(template.options).merge(
          parameters: to_request_parameters(merged_parameters),
          capabilities: capabilities
        )
      when :update_stack
        update_stack_request_params.merge(template.options).merge(
          parameters: to_request_parameters(merged_parameters),
          capabilities: capabilities,
          use_previous_template: template.options[:template_body].nil? && template.options[:template_url].nil?
        )
      else
        delete_stack_request_params
      end
    end

    def merged_parameters
      merged_params = template.parsed_parameters
      merged_params.merge!(file_parameters) if file_parameters
      depends.each do |dependent_stack_name|        
        this_stack = Stack.new({
          cloudformation: cloudformation,
          stack_name: dependent_stack_name
        })
        merged_params.select { |param|
          !this_stack[mapped_key(param.to_s)].nil?
        }.each do | param_name, param_value |
          merged_params.merge!(param_name => this_stack[mapped_key(param_name)])
        end
      end
      merged_params.merge!(user_defined_parameters)
    end

    def mapped_key(param)
      if parameter_map.has_key?(param.to_sym)
        parameter_map[param.to_sym]
      else
        param.to_sym
      end
    end

    def dry_run_response
      DRY_RUN_RESPONSE.new('arn:stackit:dry-run:complete')
    end

  end
end
