module Stackit
  class Packer

    attr_accessor :template
    attr_accessor :template_vars
    attr_accessor :options

    def initialize(template, vars, options)
      self.template = template
      self.template_vars = vars
      self.options = options
    end

    def chef_attributes_file
      template_vars[:chef_attributes_file]
    end

    def build
      env = Stackit.debug ? { 'PACKER_LOG' => '1' } : {}
      shellout = Mixlib::ShellOut.new(
        "packer build #{vars_string} #{template}",
        live_stream: STDOUT,
        env: env,
        timeout: timeout,
        logger: Stackit.logger
      )
      shellout.run_command
      raise "Packer build failed with error: #{shellout.stderr}" if shellout.error?
    end

  protected

    def packer_template_vars
      {
        aws_access_key: options[:access_key] || Stackit.aws.credentials.credentials.access_key_id,
        aws_secret_key: options[:secret_key] || Stackit.aws.credentials.credentials.secret_access_key,
        region: options[:region] || Stackit.aws.region,
      }.merge(template_vars)
    end

  private

    def vars_string
      packer_template_vars.inject([]) do |acc,pair|
        acc << "-var '#{pair[0]}=#{pair[1]}'"
      end.join(' ')
    end

    def timeout
      options[:timeout] ? options[:timeout].minutes : 15.minutes
    end

  end
end
