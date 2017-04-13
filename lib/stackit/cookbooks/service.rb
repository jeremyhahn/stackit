require_relative 'service'

module Stackit::Cookbooks
  class Service

    attr_accessor :options

    def initialize(options)
    	self.options = options
    end

    def package
      package_cookbooks
      cookbook_archive
    end

    def upload
      Stackit.aws.s3.put_object(
      	bucket: vpc_devops_bucket,
      	key: cookbook_bucket_key,
      	body: cookbook_archive_body,
      	content_type: "application/zip, application/octet-stream"
      )
      "s3://#{vpc_devops_bucket}/#{cookbook_bucket_key}"
    end

    def deploy
      package
      s3_uri = upload
      FileUtils.rm(cookbook_archive)
      s3_uri
    end

  protected

    def cookbook_home
      options[:cookbooks] || "../cookbooks"
    end

    def cookbook_archive
      "#{cookbook_home}/#{cookbook_archive_name}"
    end

    def cookbook_archive_name
      options[:cookbook_archive_name] || environment_config[options[:provisioner]][:cookbooks_artifact_name] || "cookbooks.tar.gz"
    end

    def cookbook_archive_body
      File.read(cookbook_archive)
    end

    def package_cookbooks
      raise "Unable to locate cookbooks at: #{cookbook_home}" unless File.directory?(cookbook_home)
      raise "Failed to berks package" unless Stackit::Shellout.exec("berks package #{cookbook_archive_name}", cookbook_home)
    end

    def vpc_devops_bucket
      raise "Unable to locate environment configuration for '#{Stackit.environment}'" if environment_config.nil?
      key = options[:vpc_key] ? options[:vpc_key].to_sym : environment_config[:devops_bucket_key]
      Stackit::ParameterResolver.new(vpc_stack).resolve(key)
    end

    def cookbook_bucket_key
      options[:bucket_key] || "cookbooks.tar.gz"
    end

  private

    def vpc_stack_name
      @vpc_stack_name ||= (options[:vpc] || "#{Stackit.configuration[:global][:vpc][:name]}-#{Stackit.environment}")
    end

    def vpc_stack
      @vpc_stack ||= Stackit::Stack.new(stack_name: vpc_stack_name)
    end

    def environment_config
      @environment_config ||= begin
        config = Stackit.configuration[Stackit.environment]
        raise "Unable to locate environment: '#{Stackit.environment}' in config file '#{Stackit.configuration_file}'" if config.nil?
        config
      end
    end

  end
end
