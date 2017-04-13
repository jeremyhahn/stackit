require_relative 'service'

module Stackit::Cookbooks

  class Cli < Stackit::BaseCli

    include Thor::Actions

    class_option :cookbooks, aliases: '-c', desc: 'Path to cookbooks'
    class_option :vpc, aliases: '-v', desc: 'The target VPC stack name'
    class_option :bucket, aliases: '-b',  desc: 'Uploads the packaged archive to the specified bucket'
    class_option :bucket_key, aliases: '-k', desc: 'Relative path for the object (mydir/cookbooks.tar.gz)'

    def initialize(*args)
      super(*args)
    end

    def self.initialize_cli
      Thor.desc "cookbooks", "Manages the Chef cookbooks"
      Thor.subcommand "cookbooks", self
    end

    desc 'package', 'Performs a berks install, update and package'
    def package
      say_status 'OK', Service.new(options).package
    end

    desc 'upload', 'Uploads a packages cookbooks archive to S3'
    def upload
      say_status 'OK', Service.new(options).upload
    end

    desc 'deploy', 'Packages and uploads a cookbook archive to S3'
    def deploy
      say_status 'OK', Service.new(options).deploy
    end

  end

end
