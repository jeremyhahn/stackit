module Stackit::Generate::Toolkit
  class ToolkitTemplateBinding

    attr_accessor :toolkit_name
    attr_accessor :toolkit_module_name

    def initialize(options)
      self.toolkit_name = options[:toolkit_name]
      self.toolkit_module_name = options[:toolkit_module_name]
    end

    def get_binding
      binding()
    end

  end
end

