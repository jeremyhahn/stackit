require "pp"
require "logger"
require "json"
require "configliere"
require "active_support"
require "active_support/all"
require "awsclient"
require "stackit/version"
require "stackit/aws"
require "stackit/template"
require "stackit/stack/default_notifier"
require "stackit/wait"
require "stackit/stack"
require "stackit/stack/parameter_resolver"
require "stackit/stack/managed_stack"
require "stackit/bucket"
require "stackit/artifact"
require "stackit/shellout"
require "stackit/service/managed_stack_service"
require "stackit/cookbooks/service"

module Stackit
  class << self

    attr_accessor :aws
    attr_accessor :cloudformation
    attr_accessor :logger
    attr_accessor :environment
    attr_accessor :debug
    attr_accessor :home
    attr_accessor :configuration_file
    attr_accessor :toolkit_name

    def aws(options = {})
      @aws ||= Stackit::Aws.new(options)
    end

    def cloudformation
      @cloudformation ||= aws.cloudformation
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def environment
      @environment ||= :default
    end

    def debug
      @debug ||= false
    end

    def home
      Pathname.new(File.expand_path('stackit.gemspec', __dir__)).dirname
    end

    def configuration=(config_file)
        self.configuration_file = config_file
        Stackit.logger.debug "Configuration: #{configuration_file}"
        @configuration = ::Settings.read(config_file)
    end

    def configuration
      @configuration ||= begin
        if File.file?("#{ENV['HOME']}/stackit-#{Stackit.environment}.yml")
          self.configuration_file = "#{ENV['HOME']}/stackit-#{Stackit.environment}.yml"
        elsif File.file?("#{ENV['HOME']}/stackit-#{Stackit.environment}.yml")
          self.configuration_file = "#{ENV['HOME']}/stackit-#{Stackit.environment}.yml"
        elsif File.file?("#{ENV['HOME']}/stackit.yml")
          self.configuration_file = "#{ENV['HOME']}/stackit.yml"
        elsif File.file?("./stackit.yml")
          self.configuration_file = "./stackit.yml"
        else
          raise "Unable to locate stackit configuration file"
        end
        logger.debug "Configuration: #{configuration_file}"  
        ::Settings.read(configuration_file)
      end
    end

    def toolkit_name
      Stackit.configuration[:global][:toolkit][:name]
    end

    def toolkit_namespace
      toolkit_name.capitalize
    end

    def environment_config
      @environment_config ||= begin
        conf = Stackit.configuration[Stackit.environment]
        raise "Unable to load configuration for environment: '#{Stackit.environment}'" if conf.nil?
        conf
      end
    end

  end
end

module Stackit::Mixin; end
