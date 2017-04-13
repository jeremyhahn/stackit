require 'erb'
require 'net/http'
require 'uri'
require 'stackit/generate/template_writer'
require 'stackit/generate/cookbook/service'
require 'stackit/generate/toolkit/service'

module Stackit::Generate

  class StackTemplateBinding
    attr_accessor :toolkit_namespace, :module_name, :tier_name, :stack_type, :vpc_name,
                  :vpc_description, :cidr, :cidr_network, :devops_bucket_name, :remote_access_network,
                  :public_hosted_zone_name, :private_hosted_zone_name,
                  :super_stack, :app_name, :repository
    def initialize(options)
      self.cidr = options[:cidr] || Stackit.environment_config[:cidr]
      cidr_pieces = cidr.split('.')
      self.cidr_network = "#{cidr_pieces[0]}.#{cidr_pieces[1]}"
      self.toolkit_namespace = options[:toolkit]
      self.module_name = options[:module_name]
      self.tier_name = options[:tier_name]
      self.stack_type = options[:stack_type]
      self.vpc_name = options[:vpc_name] || Stackit.configuration[:global][:vpc][:name]
      self.vpc_description = Stackit.configuration[:global][:vpc][:description]
      self.public_hosted_zone_name = options[:public_hosted_zone_name]
      self.private_hosted_zone_name = options[:private_hosted_zone_name]
      self.devops_bucket_name = options[:devops_bucket]
      self.remote_access_network = options[:remote_access_network]
      self.super_stack = options[:super_stack]
      self.app_name = options[:app_name]
      self.repository = options[:repository]
    end
    def get_binding
      binding()
    end
  end

  class Cli < Stackit::BaseCli

    def initialize(*args)
      super(*args)
    end

    class_option :toolkit, desc: 'Optional toolkit namespace. Defaults to the current toolkit namespace'

    def self.initialize_cli
      Thor.desc "generate", "Performs code and template scaffolding"
      Thor.subcommand "generate", self
    end

    desc 'toolkit', 'Generate a new toolkit'
    method_option :name, aliases: '-n', desc: 'The toolkit name', :required => true
    method_option :path, aliases: '-p', desc: 'A file system path to output the generated toolkit'
    def toolkit
      Toolkit::Service.new(options).gen
    end

    desc 'cookbooks', 'Chef cookbook scaffolding'
    method_option :name, aliases: '-n', desc: 'The cookbook name', :required => true
    method_option :output, aliases: '-p', desc: 'A file system path to output the generated cookbook'
    method_option :ssh_keypair, aliases: '-k', desc: 'Optional. Defaults to environment configuration (default_ssh_keypair)'
    method_option :security_group_id,  desc: 'Optional. Defaults to environment configuration (default_security_group_key)'
    method_option :availability_zone, desc: 'Optional. Defaults to environment configuration (kitchen/availability_zone)'
    method_option :subnet_id, desc: 'Optional. Defaults to first subnet defined in configuration (tier_map)'
    method_option :iam_profile_name, desc: 'Optional. Defaults to environment configuration (default_ssh_keypair)'
    method_option :instance_type, desc: 'Optional. Defaults to environment configuration (default_instance_type)'
    method_option :associate_public_ip, desc: 'Optional. Defaults to environment configuration (kitchen/associate_public_ip)'
    method_option :ssh_private_key, desc: 'Optional. Defaults to environment configuration (default_ssh_private_key)'
    method_option :ami, desc: 'Optional. Defaults to environment configuration (default_ami_id)'
    method_option :kitchen_driver, desc: 'Optional. Defaults to environment configuration (kitchen/default_driver)', :default => 'ec2'
    def cookbooks
      Cookbook::Service.new(options).gen
    end

    desc 'vpc', 'Generate a VPC'
    method_option :name, aliases: '-n', desc: 'Optional vpc name. Defaults to configuration file (global/vpc/name)'
    method_option :description, aliases: '-n', desc: 'Optional vpc description'
    method_option :type, aliases: '-t', desc: 'The type of stack', :default => 'vpc'
    method_option :template, aliases: '-n', desc: 'The vpc template (simple | tiered)', :default => 'simple'
    method_option :template_path, type: :string, desc: 'Optional path to directory containing source ERB templates'
    method_option :cidr, aliases: '-c', desc: 'Optional vpc network CIDR. Defaults to environment config (cidr)'
    method_option :devops_bucket, aliases: '-b', desc: 'Optional devops S3 bucket name'
    method_option :remote_access_cidr, aliases: '-b', desc: 'Optional remote access network to allow into the VPC. Defaults to current public IP'
    method_option :public_hosted_zone_name, aliases: '-b', desc: 'Optional domain name used as the VPCs public hosted zone'
    method_option :private_hosted_zone_name, aliases: '-b', desc: 'Optional domain name used as the VPCs private internal hosted zone'
    method_option :output, aliases: '-o', desc: 'Optional output path. Defaults to current working directory', :default => '.'
    method_option :cli, type: :boolean, desc: 'True/false flag indicating whether to generate a CLI', :default => true
    method_option :service, type: :boolean, desc: 'True/false flag indicating whether to generate a service', :default => true
    def vpc
      config = Stackit.configuration
      stack_path = "#{options[:output]}/vpc"
      Dir.mkdir stack_path unless File.exist?(stack_path)
      template_binding = StackTemplateBinding.new(
        :toolkit => toolkit_namespace,
        :module_name => module_name,
        :stack_type => stack_type.downcase,
        :vpc_name => vpc_name,
        :vpc_description => vpc_description,
        :cidr => options[:cidr],
        :devops_bucket => devops_bucket_name,
        :remote_access_network => remote_access_network,
        :public_hosted_zone_name => public_hosted_zone_name,
        :private_hosted_zone_name => private_hosted_zone_name
      ).get_binding
      gen_erb("vpc/#{options[:template]}.parameters", template_binding, stack_path, "vpc-#{Stackit.environment}.parameters")
      gen_erb("vpc/#{options[:template]}.json", template_binding, stack_path, "vpc.json")
      gen_erb("vpc/cli.rb", template_binding, stack_path, "cli.rb") if options[:cli]
      gen_erb("vpc/service.rb", template_binding, stack_path, "service.rb") if options[:service]
    end

    desc 'stack', 'Generate a stack that contains a CLI, ManagedStackService and cloudformation template'
    method_option :type, aliases: '-t', desc: 'The type of stack (webserver, vpnserver, hadoopcluster)', :required => true
    method_option :tier, type: :string, desc: 'What tier does this stack belong to', :required => true
    method_option :provisioner, aliases: '-p', desc: 'A supported provisioner - currently only chefsolo supported!', :default => 'chefsolo'
    method_option :template, desc: 'The name of the source template used to generate the target template', :default => 'instance'
    method_option :template_path, type: :string, desc: 'Optional path to directory containing source ERB templates'
    method_option :cli, type: :boolean, desc: 'True/false flag indicating whether to generate a CLI', :default => true
    method_option :service, type: :boolean, desc: 'True/false flag indicating whether to generate a service', :default => true
    method_option :packer, type: :boolean, desc: 'True/false flag indicating whether to generate a packer template', :default => true
    method_option :output, aliases: '-o', desc: 'Optional output path. Defaults to current working directory', :default => '.'
    def stack
      stack_path = "#{options[:output]}/#{options[:type]}"
      template_binding = StackTemplateBinding.new(
        :toolkit => toolkit_namespace,
        :module_name => module_name,
        :stack_type => stack_type.downcase,
        :tier_name => options[:tier],
        :vpc_name => vpc_name,
        :vpc_description => vpc_description
      ).get_binding
      Dir.mkdir stack_path unless File.exist?(stack_path)
      gen_erb('stack/stack-cli.rb', template_binding, stack_path, "cli.rb") if options[:cli]
      gen_erb('stack/stack-service.rb', template_binding, stack_path,"service.rb") if options[:service]
      gen_erb("stack/packer.json", template_binding, stack_path, "packer.json") if options[:packer]
      gen_erb("stack/#{options[:provisioner]}-#{options[:template]}.json", template_binding, stack_path, "node.json")
    end

    desc 'pipeline', 'Generate a stack that contains a CLI, CodePipelineManagedStackService and CodePipeline template for the specified stack'
    method_option :super_stack, aliases: '-s', desc: 'The parent / super stack the pipeline supports', :required => true
    method_option :app_name, aliases: '-a', desc: 'The parent / super stack the pipeline supports', :required => true
    method_option :repository, aliases: '-r', desc: 'Optional github repository name. Defaults to app_name'
    method_option :type, aliases: '-t', desc: 'The type of stack (webserver, vpnserver, hadoopcluster)', :required => true
    method_option :template, desc: 'The name of the source template used to generate the target template', :default => 'codepipeline'
    method_option :template_path, type: :string, desc: 'Optional path to directory containing source ERB templates'
    method_option :cli, type: :boolean, desc: 'True/false flag indicating whether to generate a CLI', :default => true
    method_option :service, type: :boolean, desc: 'True/false flag indicating whether to generate a service', :default => true
    method_option :output, aliases: '-o', desc: 'Optional output path. Defaults to current working directory', :default => '.'
    def pipeline
      stack_path = "#{options[:output]}/#{options[:type]}"
      template_binding = StackTemplateBinding.new(
        :toolkit => toolkit_namespace,
        :module_name => module_name,
        :stack_type => stack_type.downcase,
        :tier_name => options[:tier],
        :vpc_name => vpc_name,
        :vpc_description => vpc_description,
        :super_stack => options[:super_stack],
        :app_name => options[:app_name],
        :repository => options[:repository] || options[:app_name]
      ).get_binding
      Dir.mkdir stack_path unless File.exist?(stack_path)
      gen_erb('stack/pipeline_service.rb', template_binding, stack_path, "pipeline_service.rb") if options[:service]
      gen_erb('stack/stack-cli.rb', template_binding, stack_path, "cli.rb") if options[:cli]
      gen_erb("stack/pipeline.json", template_binding, stack_path, "pipeline.json")
    end

    no_commands do

      def toolkit_namespace
        options[:toolkit] ? options[:toolkit].capitalize : Stackit.toolkit_namespace
      end

      def public_hosted_zone_name
        options[:public_hosted_zone_name] || "#{Stackit.environment}.#{vpc_name}.com"
      end

      def private_hosted_zone_name
        options[:public_hosted_zone_name] || "#{Stackit.environment}.#{vpc_name}.local"
      end

      def devops_bucket_name
        options[:devops_bucket] || Stackit.environment_config[:devops_bucket_name] || "#{vpc_name}-#{Stackit.environment}"
      end

      def remote_access_network
        options[:remote_access_network] || "#{current_public_ip}/32"
      end

      def current_public_ip
        Net::HTTP.get(URI('https://api.ipify.org'))
      end

      def vpc_name
        options[:name] || Stackit.configuration[:global][:vpc][:name]
      end

      def vpc_description
        options[:description] || Stackit.configuration[:global][:vpc][:description] || "#{vpc_name} for AWS"
      end

      def stack_type
        options[:type]
      end

      def module_name
        @module_name ||= stack_type.capitalize
      end

      def template_path
        @template_path ||= options[:template_path] || "#{Stackit.home}/stackit/generate/templates"
      end

      def gen_erb(template_name, template_binding, stack_path, output_name)
        Stackit.logger.debug "Generate #{module_name}:#{output_name}"
        service_template = File.open("#{template_path}/#{template_name}.erb").read
        service_erb_template = ERB.new(service_template, nil, '-')
        content = service_erb_template.result(template_binding)
        File.open("#{stack_path}/#{output_name}", "w+") { |file|
          file.write(content)
        }
      end

    end

  end

end