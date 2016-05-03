module Stackit

  class ManagedStackService

    attr_accessor :options
    attr_accessor :stacks

    def initialize(options)
      self.options = options
    end

    def create!
      stack.create!
    end

    def update!
      stack.update!
    end

    def delete!
      Stackit::ManagedStack.new(
        stack_name: stack_name
      ).delete!
    end

  protected

    def stack_name
      return options[:stack_name] ||  
        "#{Stackit.environment}-#{options[:stack_name]}"
    end

    def template
      return options[:template] ||
        File.expand_path("#{options[:stack_name]}.json", template_dir)
    end

    def parameters_file
      return options[:parameters_file] ||
        File.expand_path("#{options[:stack_name]}.parameters", template_dir)
    end

    def parameter_mappings
      {}
    end

    def user_defined_parameters
      {}
    end

    def template_dir
      dir = options[:template_dir] ? options[:template_dir] : __dir__
    end

    def stack
      ManagedStack.new(
        template: template,
        stack_name: stack_name,
        stack_policy: options[:stack_policy],
        stack_policy_during_update: options[:stack_policy_during_update],
        depends: options[:depends],
        user_defined_parameters: user_defined_parameters,
        parameters_file: parameters_file,
        parameter_map: parameter_mappings,
        wait: options[:wait],
        force: options[:force],
        dry_run: options[:dry_run],
        debug: !!options[:debug]
      )
    end

    def depends_stacks
      stacks = []
      options[:depends].each do |stack|
        stacks << Stackit::Stack.new(stack_name: stack)
      end
      stacks
    end

    def stacks
      @stacks ||= [stack].concat(depends_stacks)
    end

    def resolve_parameter(key)
      depends_stacks.each do |s|
        value = s[key]
        return value unless value.nil?
      end
    end

  end
end
