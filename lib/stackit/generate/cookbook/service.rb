require 'stackit/generate/cookbook/kitchen_template_binding'
require 'stackit/generate/cookbook/service_template_binding'

module Stackit::Generate::Cookbook

  class Service

    attr_accessor :options
    attr_accessor :output_path
    attr_accessor :cookbook_home

    def initialize(options)
      self.options = options
      self.output_path = cookbook_output_path
    end

    def gen
      gen_dirs
      gen_metadata_rb
      gen_kitchen_yml
      gen_vagrantfile
      gen_readme
      gen_recipes
      gen_attributes
      copy_static_files
      add_cookbook_to_top_level_berksfile
    end

  private

    def environment_config
      @environment_config ||= begin
        env = Stackit.configuration[Stackit.environment]
        raise "Unable to locate environment '#{Stackit.environment}' in configuration file." if env.nil?
        env
      end
    end

    def kitchen_config
      @kitchen_config ||= environment_config[:kitchen]
    end

    def cookbook_name
      options[:name]
    end

    def cookbook_output_path
      if options[:output] 
        outpath = "#{options[:output]}/#{cookbook_name}"
        self.cookbook_home = options[:output]
        create_cookbook_home_if_not_exist
      else
        outpath = "./#{cookbook_name}"
        self.cookbook_home = '.'
        create_cookbook_home_if_not_exist
      end
      outpath
    end

    def create_cookbook_home_if_not_exist
      if !File.file?("#{cookbook_home}/Berksfile")
        FileUtils.mkdir_p cookbook_home unless File.directory?(cookbook_home)
        FileUtils.cp(static_file('Berksfile-root'), "#{cookbook_home}/Berksfile")
        FileUtils.cp(static_file('Gemfile'), "#{cookbook_home}/Gemfile")
        self.output_path = "#{cookbook_home}/#{cookbook_name}"
      end
    end

    def add_cookbook_to_top_level_berksfile
      cookbook_name = options[:name]
      open("#{cookbook_home}/Berksfile", 'a') { |file|
        content = File.read(file)
        file.puts "cookbook '#{options[:name]}', path: '#{cookbook_name}'" unless (content[/cookbook\s+\'#{cookbook_name}/])
      }
    end

    def gen_metadata_rb
      Stackit::Generate::TemplateWriter.new(
        :output_path => output_path,
        :template => template_path('metadata.rb'),
        :template_binding => service_name_template_binding,
        :filename => 'metadata.rb'
      ).write!
    end

    def gen_kitchen_yml
      Stackit::Generate::TemplateWriter.new(
        :output_path => output_path,
        :template => template_path(".kitchen-#{options[:kitchen_driver]}.yml"),
        :template_binding => kitchen_template_binding,
        :filename => '.kitchen.yml'
      ).write!
    end

    def gen_vagrantfile
      Stackit::Generate::TemplateWriter.new(
        :output_path => output_path,
        :template => template_path('Vagrantfile'),
        :template_binding => service_name_template_binding,
        :filename => 'Vagrantfile'
      ).write!
    end

    def gen_readme
      Stackit::Generate::TemplateWriter.new(
        :output_path => output_path,
        :template => template_path('README.md'),
        :template_binding => service_name_template_binding,
        :filename => 'README.md'
      ).write!
    end

    def gen_dirs
      attrs = "#{output_path}/attributes"
      recipes = "#{output_path}/recipes"
      FileUtils.mkdir_p "#{output_path}/test/integration/default/serverspec/localhost"
      Dir.mkdir attrs unless File.exist?(attrs)
      Dir.mkdir recipes unless File.exist?(recipes)
    end

    def gen_recipes
      FileUtils.touch("#{output_path}/recipes/default.rb")
    end

    def gen_attributes
      FileUtils.touch("#{output_path}/attributes/default.rb")
    end

    def copy_static_files
      FileUtils.cp(static_file('Berksfile'), "#{output_path}/Berksfile")
      FileUtils.cp(static_file('chefignore'), "#{output_path}/chefignore")
      FileUtils.cp(static_file('Gemfile'), "#{output_path}/Gemfile")
      FileUtils.cp(static_file('Thorfile'), "#{output_path}/Thorfile")
      FileUtils.cp(static_file('.gitignore'), "#{output_path}/.gitignore")
      FileUtils.cp(static_file('/test/integration/default/serverspec/spec_helper.rb'), "#{output_path}/test/integration/default/serverspec/spec_helper.rb")
      FileUtils.cp(static_file('/test/integration/default/serverspec/localhost/default_spec.rb'), "#{output_path}/test/integration/default/serverspec/localhost/default_spec.rb")
    end

    def static_file(file)
      "#{Stackit.home}/stackit/generate/templates/cookbook/#{file}"
    end

    def template_path(template)
      "#{Stackit.home}/stackit/generate/templates/cookbook/#{template}.erb"
    end

    def service_name_template_binding
      ServiceNameTemplateBinding.new(
        service_name: options[:name]
      ).get_binding
    end

    def vpc_stack_name
      @vpc_stack_name ||= options[:vpc] || 
        "#{Stackit.configuration[:global][:vpc][:name]}-#{Stackit.environment}"
    end

    def vpc_stack
      @vpc_stack ||= Stackit::Stack.new(stack_name: vpc_stack_name)
    end

    def default_subnet_id
      begin
        tiers = environment_config[:tiers]
        tier_key = tiers.keys.first
        subnet_key = tiers[tier_key].values.first
        Stackit::ParameterResolver.new(vpc_stack).resolve(subnet_key)
      rescue TypeError => e
        Stackit.logger.debug e.message
        ""
      end
    end

    def default_security_group
      begin
        Stackit::ParameterResolver.new(vpc_stack).resolve(environment_config[:default_security_group_key])
      rescue TypeError => e
        Stackit.logger.debug e.message
        ""
      end 
    end

    def parameter(key)
      
    end

    def kitchen_template_binding
      KitchenTemplateBinding.new(
        :aws_ssh_key => options[:ssh_keypair] || environment_config[:default_ssh_keypair],
        :region => Stackit.aws.region,
        :security_group => options[:security_group_id] || default_security_group,
        :availability_zone => kitchen_config[:availability_zone],
        :subnet_id => options[:subnet_id] || default_subnet_id,
        :iam_profile_name => options[:iam_profile_name] || kitchen_config[:iam_profile_name],
        :instance_type => options[:instance_type] || kitchen_config[:instance_type],
        :associate_public_ip => options[:associate_public_ip] || kitchen_config[:associate_public_ip],
        :transport_ssh_key => options[:ssh_private_key] || environment_config[:default_ssh_private_key],
        :transport_username => options[:ssh_username] || environment_config[:default_ssh_private_key],
        :platform_ami => options[:ami] || environment_config[:default_ami_id],
        :platform_username => options[:ssh_username] || environment_config[:default_ssh_username],
        :service_name => options[:name]
      ).get_binding
    end

  end

end
