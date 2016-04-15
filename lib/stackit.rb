require "logger"
require "pp"
require "json"
require "active_support"
require "active_support/all"
require "awsclient"
require "stackit/version"
require "stackit/aws"
require "stackit/template"
require "stackit/stack/default_notifier"
require "stackit/stack"
require "stackit/stack/managed_stack"

module Stackit
  class << self

    attr_accessor :aws
    attr_accessor :cloudformation
    attr_accessor :logger
    attr_accessor :environment
    attr_accessor :debug
    attr_accessor :home

    def aws
      @aws ||= Stackit::Aws.new
    end

    def cloudformation
      @cloudformation ||= Stackit::Aws.new.cloudformation
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
