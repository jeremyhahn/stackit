require "logger"
require "json"
require "pp"
require "active_support"
require "active_support/all"
require "awsclient"
require "stackit/version"
require "stackit/aws"
require "stackit/template"
require "stackit/stack/default_notifier"
require "stackit/wait"
require "stackit/stack"
require "stackit/stack/managed_stack"
require "stackit/stack/managed_stack_service"
require "stackit/stack/parameter_resolver"

module Stackit
  class << self

    attr_accessor :aws
    attr_accessor :cloudformation
    attr_accessor :logger
    attr_accessor :environment
    attr_accessor :debug
    attr_accessor :home

    def aws(options)
      @aws ||= Stackit::Aws.new(options)
    end

    def aws=(aws)
      @aws = aws
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

  end
end

module Stackit::Mixin; end

require "stackit/stack/opsworks_managed_stack_service"
