require 'stackit/packer'

module Stackit::Mixin::Packer

  def packer_config
    @packer_config ||= Stackit.environment_config[:packer]
  end

  def packer_template
    @packer_template ||= begin
      if File.file?("#{stack_type}/packer.json")
        "#{stack_type}/packer.json"
      else
        options[:packer_template] ||
        File.expand_path("packer.json", stack_path) ||
        packer_config[:default_template_name]
      end
    end
  end

  def pack!
    packer = Stackit::Packer.new(
      packer_template,
      packer_vars,
      options
    )
    File.write(packer.chef_attributes_file, build_attributes(chef_attributes))
    packer.build
  end

end
