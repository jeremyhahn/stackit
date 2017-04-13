module Stackit::Generate::Cookbook

  class ServiceNameTemplateBinding

    attr_accessor :service_name

    def initialize(options)
      self.service_name = options[:service_name]
    end

    def get_binding
      binding()
    end

  end
end

