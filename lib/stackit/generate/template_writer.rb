module Stackit::Generate
  class TemplateWriter

    attr_accessor :output_path
    attr_accessor :template
    attr_accessor :template_binding
    attr_accessor :filename

    def initialize(options)
      self.output_path = options[:output_path]
      self.template = options[:template]
      self.template_binding = options[:template_binding]
      self.filename = options[:filename]
    end

    def write!
      t = File.open(template).read
      erb_template = ERB.new(t, nil, '-')
      content = erb_template.result(template_binding)
      File.open("#{output_path}/#{filename}", "w+") { |file|
        file.write(content)
      }
    end

  end
end
