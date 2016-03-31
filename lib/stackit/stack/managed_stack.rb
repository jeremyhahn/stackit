module Stackit
  class ManagedStack < Stack

    attr_accessor :template
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
      options = options.to_h.symbolize_keys!
      @template = create_template(options[:template])
      @user_defined_parameters = symbolized_user_defined_parameters(options[:user_defined_parameters])
      @parameter_map = symbolized_parameter_map(options[:parameter_map])
      @stack_name = options[:stack_name] || default_stack_name
      @depends = options[:depends] || []
      @debug = !!options[:debug] || Stackit.debug
      @force = options[:force]
      @wait = options[:wait]
      @dry_run = options[:dry_run]
      @notifier = options[:notifier] || Stackit::ThorNotifier.new
      parse_file_parameters(options[:parameters_file]) if options[:parameters_file]
    end

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
        []
      end
    end

    def default_stack_name
      self.class.name.demodulize
    end

    def create_template(t)
      template_path = t ? t : File.join(Dir.pwd, 'cloudformation', "#{stack_name.underscore.dasherize}.json")
      return unless File.exist?(template_path)
      template = Template.new(:template_path => template_path)
      template.parse!
    end

    def parse_file_parameters(parameters_file)
      if File.exist?(parameters_file)
        @file_parameters = {}
        file_params = JSON.parse(File.read(parameters_file))
        file_params.inject(@file_parameters) do |hash, param|
          hash.merge!(param['ParameterKey'].to_sym => param['ParameterValue'])
        end
      end
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
      elsif exists?
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

    def capabilities
      template.needs_iam_capability? ? ['CAPABILITY_IAM'] : []
    end

    def cloudformation_request(action)
      Stackit.logger.debug "ManagedStack CloudFormation API request: #{action}"
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
        {
          parameters: to_request_parameters(merged_parameters),
          capabilities: capabilities
        }.reverse_merge(template.options).reverse_merge(create_stack_request_params)
      when :update_stack
        {
          parameters: to_request_parameters(merged_parameters),
          capabilities: capabilities
        }.merge(template.options).merge(update_stack_request_params)
      else
        delete_stack_request_params
      end
    end

    def dependent_parameters
      depends.inject([]) do |arr, dep|
        arr.push(Stackit::Stack.new(stack_name))
      end
    end

    def merged_parameters

      parsed_parameters = template.parsed_parameters
      return parsed_parameters unless depends.length

      validated_parameters = parsed_parameters.clone

      # merge file parameters
      validated_parameters.merge!(file_parameters) if file_parameters

      # merge --depends
      depends.each do |dependent_stack_name|
        this_stack = Stack.new({
          cloudformation: cloudformation,
          stack_name: dependent_stack_name
        })
        validated_parameters.select { |param|
          !this_stack[mapped_key(param.to_s)].nil?
        }.each do | param_name, param_value |
          validated_parameters.merge!(param_name => this_stack[mapped_key(param_name)])
        end
      end

      # merge user defined parameters
      validated_parameters.merge!(user_defined_parameters)
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
