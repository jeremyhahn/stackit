module Stackit

  class ManagedStackService

    attr_accessor :options

    def initialize(options)
      self.options = options
    end

    def create!
      Stackit::ManagedStack.new(
        template: template,
        stack_name: stack_name,
        stack_policy: options[:stack_policy],
        depends: options[:depends],
        parameters_file: parameters_file,
        parameter_map: parameter_mappings,
        wait: options[:wait],
        force: options[:force],
        dry_run: options[:dry_run],
        debug: !!options[:debug]
      ).create!
    end

    def update!
      ManagedStack.new(
        template: template,
        stack_name: stack_name,
        stack_policy: options[:stack_policy],
        stack_policy_during_update: options[:stack_policy_during_update],
        depends: options[:depends],
        parameters_file: parameters_file,
        parameter_map: parameter_mappings,
        wait: options[:wait],
        force: options[:force],
        dry_run: options[:dry_run],
        debug: !!options[:debug]
      ).update!
    end

    def delete!
      Stackit::ManagedStack.new(
        stack_name: stack_name
      ).delete!
    end

  protected

    def stack_name
      return options[:stack_name] ||  "#{Stackit.environment}-#{options[:stack_name]}"
    end

    def template
      return options[:template] || File.expand_path("#{options[:stack_name]}.json", template_dir)
    end

    def parameters_file
      return options[:parameters_file || File.expand_path("#{options[:stack_name]}.parameters", template_dir)
    end

    def parameter_mappings
      {}
    end

    def template_dir
      dir = options[:template_dir] ? options[:template_dir] : __dir__
    end

  end
end
