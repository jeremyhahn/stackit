require 'stackit'
require 'thor'

module Stackit
  class Cli < Thor

    class_option :environment, :aliases => '-e', :desc => "Your stack environment (dev, staging, prod, etc)", :default => 'default'
    class_option :profile, desc: 'AWS profile'
    class_option :region, desc: 'AWS region', default: 'us-east-1'
    class_option :debug, type: :boolean, default: false
    class_option :verbose, type: :boolean, default: false
    class_option :assume_role, type: :hash, :desc => 'IAM role name and optional duration to keep the STS token valid'

    def initialize(*args)
      super(*args)
      init_cli
    end

    def self.banner(task, namespace = true, subcommand = false)
      #"#{basename} #{subcommand_prefix} #{task.usage}"
      "#{basename} #{task.usage}"
    end

    def self.subcommand_prefix
      self.name.gsub(%r{.*::}, '').gsub(%r{^[A-Z]}) { |match| match[0].downcase }.gsub(%r{[A-Z]}) { |match| "-#{match[0].downcase}" }
    end

    desc 'create-stack', 'Creates a new CloudFormation stack'
    method_option :template, aliases: '-t', desc: 'The cloudformation template', :required => true
    method_option :stack_name, aliases: '-n', desc: 'The stack name. Defaults to the camelized template file name', :required => true
    method_option :stack_policy, :aliases => '-p', :desc => 'A local file system or S3 (HTTPS) path to the stack policy'
    method_option :depends, :aliases => '-d', :type => :array, :default => [], :desc => 'Space delimited list of stack names to automatically map parameter values from'
    method_option :parameters, aliases: '-p', type: :hash, desc: 'Parameters supplied to the cloudformation template', default: {}
    method_option :parameters_file, desc: 'Parameters supplied to the cloudformation template'
    method_option :parameter_map, :aliases => '-pm', type: :hash, default: {}, desc: 'Parameter map used to direct dependent parameter values to stack template parameters'
    method_option :wait, :aliases => '-w', type: :boolean, default: false, desc: 'Wait for the stack to enter STATUS_COMPLETE before returning or raise an exception if it times out'
    method_option :force, :desc => 'Force a stack update on unchanged templates'
    method_option :dry_run, :type => :boolean, :default => false, :desc => 'Run all code except AWS API calls'
    def create_stack
      ManagedStack.new({
        template: options[:template],
        stack_name: options[:stack_name],
        stack_policy: options[:stack_policy],
        depends: options[:depends],
        user_defined_parameters: options[:parameters],
        parameters_file: options[:parameters_file],
        parameter_map: options[:parameter_map],
        wait: options[:wait],
        force: options[:force],
        dry_run: options[:dry_run],
        debug: !!options[:debug]
      }).create!
    end

    desc 'update-stack', 'Updates an existing CloudFormation stack'
    method_option :template, aliases: '-t', desc: 'The cloudformation template', :required => true
    method_option :stack_name, aliases: '-n', desc: 'The stack name. Defaults to the camelized template file name', :required => true
    method_option :stack_policy, :aliases => '-p', :desc => 'A local file system or S3 (HTTPS) path to the stack policy'
    method_option :stack_policy_during_update, :aliases => '-pu', :desc => 'A local file system or S3 (HTTPS) path to the stack policy to use during update'
    method_option :depends, :aliases => '-d', :type => :array, :default => [], :desc => 'Space delimited list of stack names to automatically map parameter values from'
    method_option :parameters, aliases: '-p', type: :hash, desc: 'Parameters supplied to the cloudformation template', default: {}
    method_option :parameters_file, desc: 'Parameters supplied to the cloudformation template'
    method_option :parameter_map, :aliases => '-pm', type: :hash, default: {}, desc: 'Parameter map used to direct dependent parameter values to stack template parameters'
    method_option :wait, :aliases => '-w', type: :boolean, default: false, desc: 'Wait for the stack to enter STATUS_COMPLETE before returning or raise an exception if it times out'
    method_option :force, :desc => 'Force a stack update on unchanged templates'
    method_option :dry_run, :type => :boolean, :default => false, :desc => 'Run all code except AWS API calls'
    def update_stack
      ManagedStack.new({
        template: options[:template],
        stack_name: options[:stack_name],
        stack_policy: options[:stack_policy],
        stack_policy_during_update: options[:stack_policy_during_update],
        depends: options[:depends],
        user_defined_parameters: options[:parameters],
        parameters_file: options[:parameters_file],
        parameter_map: options[:parameter_map],
        wait: options[:wait],
        force: options[:force],
        dry_run: options[:dry_run],
        debug: !!options[:debug]
      }).update!
    end

    desc 'delete-stack', 'Deletes a CloudFormation stack'
    method_option :stack_name, aliases: '-n', desc: 'The stack name. Defaults to the camelized template file name', :required => true
    method_option :retain_resources, :aliases => '-r', :type => :array, :desc => 'Space delimited list of logical resource ids to retain after the stack is deleted'
    method_option :wait, :aliases => '-w', type: :boolean, default: false, desc: 'Wait for the stack to enter STATUS_COMPLETE before returning or raise an exception if it times out'
    method_option :dry_run, :type => :boolean, :default => false, :desc => 'Run all code except AWS API calls'
    def delete_stack
      ManagedStack.new({
        stack_name: options[:stack_name],
        wait: options[:wait],
        dry_run: options[:dry_run],
        debug: !!options[:debug]
      }).delete!
    end

    desc 'create-keypair', 'Creates a new EC2 keypair and returns it\'s corresponding private key'
    method_option :name, desc: 'The name of the keypair', :required => true
    def create_keypair
      puts Stackit.aws.ec2.create_key_pair({
        key_name: options['name']
      })['key_material']
    end

    desc 'delete-keypair', 'Deletes an existing EC2 keypair'
    method_option :name, desc: 'The name of the keypair', :required => true
    def delete_keypair
      Stackit.aws.ec2.delete_key_pair({
        key_name: options['name']
      })
    end

    desc 'version', 'Displays StackIT version'
    def version
      puts <<-LOGO
  _____   _                 _      _______  _______ 
 (_____) (_)_              (_) _  (_______)(__ _ __)
(_)___   (___) ____    ___ (_)(_)    (_)      (_)   
  (___)_ (_)  (____) _(___)(___)     (_)      (_)   
  ____(_)(_)_( )_( )(_)___ (_)(_)  __(_)__    (_)   
 (_____)  (__)(__)_) (____)(_) (_)(_______)   (_)  v#{Stackit::VERSION}

Simple, elegant CloudFormation dependency management.

LOGO
    end

    def self.exit_on_failure?
      true
    end

    no_commands do

      def init_cli

        Stackit.aws.region = options[:region] if options[:region]
        Stackit.environment = options[:environment].to_sym if options[:environment]
        Stackit.debug = !!options[:debug]
        if Stackit.debug
          Stackit.logger.level = Logger::DEBUG
          Stackit.logger.debug "Initializing CLI in debug mode."
          begin
            require 'pry-byebug'
          rescue LoadError; end
        elsif options[:verbose]
          Stackit.logger.level = Logger::INFO
        else
          Stackit.logger.level = Logger::ERROR
        end
        if options[:profile]
          Stackit.aws.profile = options[:profile]
        elsif options[:environment]
          Stackit.aws.credentials = Stackit.aws.load_credentials(
            options[:environment]
          )
        end
        if options[:assume_role] && options[:assume_role].has_key?('name')
          name = options[:assume_role]['name']
          duration = options[:assume_role].has_key?('duration') ? options[:assume_role]['duration'] : 3600
          Stackit.aws.assume_role!(name, duration)
        end
      end

    end

  end
end
