require 'stackit'
require 'thor'

module Stackit
  class StackitCli < Thor

    def initialize(*args)
      super(*args)
    end

    # TODO: Move to "ProvisionerCli"
    class_option :chef_runlist, :type => :array, :default => [], desc: 'Optional override runlist'
    class_option :chef_version, desc: 'Optional chef-solo version'
    class_option :chef_cookbooks_artifact, desc: 'Optional chef-solo version'
    class_option :provisioner, desc: 'A supported provisioner - currently only chefsolo supported!', :default => 'chefsolo'

    def self.require_clis
      self.load_stack("#{Stackit.home}/stackit/generate")
      self.load_stack("#{Stackit.home}/stackit/cookbooks") # TODO: Move to Provisioner
      Dir.glob("./*") do |stack|
        next if File.file?(stack)
        self.load_stack(stack)
      end
    end

    def self.load_stack(stack)
      stack_name = stack.split('/').last
      stack_namespace = "#{Stackit.toolkit_namespace}::#{stack_name.capitalize}::Cli"
      cli = "#{stack}/cli.rb"
      if File.exist?(cli)
        require cli
        clazz = stack_namespace.constantize
        clazz.initialize_cli if clazz.respond_to?('initialize_cli')
      end
    end

=begin
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

    desc 'list-keypairs', 'Lists EC2 keypairs'
    def list_keypairs
      pp Stackit.aws.ec2.describe_key_pairs
    end
=end

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

  end
end
