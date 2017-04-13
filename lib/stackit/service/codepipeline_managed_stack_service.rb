require 'stackit/mixin/vpc'

module Stackit
  class CodePipelineManagedStackService < Stackit::ManagedStackService

    include Stackit::Mixin::Vpc

    attr_accessor :github_config
    attr_accessor :stack_role_key
    attr_accessor :repository
    attr_accessor :branch
    attr_accessor :app_name
    attr_accessor :app_source
    attr_accessor :deployment_group_tag_key
    attr_accessor :deployment_group_tag_value

    def initialize(options)
      super(options)
      self.stack_role_key = options[:stack_policy_key] || :InstanceRole
      self.branch = options[:branch] || "master"
      self.deployment_group_tag_key = options[:deployment_group_tag_key] || "stack-type"
    end

    def stack_name
      options[:stack_name] || "#{Stackit.environment}-#{stack_type}-pipeline"
    end

    def template
      options[:template] || "#{stack_path}/pipeline.json"
    end

    def artifacts
      []
    end

    def user_defined_parameters
      {
        :Environment => Stackit.environment,
        :DevOpsBucket => devops_bucket.bucket_name,
        :GitHubToken => github_oauth_token,
        :GitHubUser => github_username,
        :Repository => repository,
        :Branch => branch,
        :AppName => app_name,
        :AppSource => app_source,
        :DeploymentGroupTagKey => deployment_group_tag_key,
        :DeploymentGroupTagValue => deployment_group_tag_value,
        :StackRole => super_stack_role,
        :StackType => stack_type
      }
    end

    def app_source
      @app_source ||= options[:source] || "https://github.com/#{github_username}/#{repository}.git"
    end

    def repository
      @repository ||= options[:repository] || "#{stack_type}"
    end

  private

    def super_stack_role
      options[:super_stack_role] || resolve_parameter(stack_role_key)
    end

    def github_oauth_token
      options[:oauth_token] || github_config[:oauth_token]
    end

    def github_username
      options[:username] || github_config[:username]
    end

    def github_config
      @github_config ||= begin
        github = Stackit.environment_config[:github]
        raise "Unable to locate github configuration in #{Stackit.configuration_file}" if github.nil?
        github
      end
    end

  end
end
