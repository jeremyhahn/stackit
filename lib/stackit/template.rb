module Stackit
  class Template

    attr_accessor :cloudformation
    attr_accessor :template_path
    attr_accessor :options
    attr_accessor :parsed_parameters

    def initialize(options = {})
      @cloudformation = options[:cloudformation] || Stackit.cloudformation
      @template_path = options[:template_path]
      @options = {}
    end

    def parse!
      Stackit.logger.info "Parsing cloudformation template: #{template_path}"
      if @template_path =~ /^https:\/\/s3\.amazonaws\.com/
        @options[:template_url] = @template_path
      else
        @options[:template_body] = body
      end
      @options[:parameters] = validate
      self
    end

    def parsed_parameters
      @parsed_parameters ||= @options[:parameters].inject({}) do |hash, param|
        hash.merge(param['parameter_key'].to_sym => param['default_value'])
      end
    end

    def needs_iam_capability?
      body =~ /AWS::IAM::AccessKey|AWS::IAM::Group|AWS::IAM::InstanceProfile|AWS::IAM::Policy|AWS::IAM::Role|AWS::IAM::User|AWS::IAM::UserToGroupAddition/ ? true : false
    end

  private

    def body
      path = File.exist?(template_path) ? template_path : File.join(Dir.pwd, template_path)
      raise "Unable to stat filesystem template #{template_path}" if !File.exist?(path)
      File.read(path)
    end

    def validate
      cloudformation.validate_template(
        options.slice(:template_body, :template_url)
      )[:parameters]
    end

  end
end
