require 'stackit'
require 'stackit/cli/base_cli'
require 'thor'

module Stackit
  class StackCli < BaseCli

    def initialize(*args)
      super(*args)
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

  end
end
