require 'stackit'
require 'thor'

module Stackit
  class StackitCli < StackCli

    def initialize(*args)
      super(*args)
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

  end
end
