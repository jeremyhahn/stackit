require 'stackit'
require 'thor'

module Stackit
  class BaseCli < Thor

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
      "#{basename} #{task.usage}"
    end

    def self.subcommand_prefix
      self.name.gsub(%r{.*::}, '').gsub(%r{^[A-Z]}) { |match| match[0].downcase }.gsub(%r{[A-Z]}) { |match| "-#{match[0].downcase}" }
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
