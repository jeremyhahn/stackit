module Stackit
  class Bucket
  
    attr_accessor :config
    attr_accessor :options
    attr_accessor :stacks
 
    def initialize(options, stacks = [])
      self.config = Stackit.configuration[Stackit.environment]
      self.stacks = stacks
      self.options = options
    end

    def bucket_key=(key)
      @bucket_key = key
    end

    def bucket_key
      @bucket_key ||= options[:bucket_key] || config[:devops_bucket_key]
    end

    def bucket_name
      @bucket_name ||= Stackit::ParameterResolver.new(stacks).resolve(bucket_key)
    end

    def bucket_name=(name)
      @bucket_name = name
    end

    def upload(artifact, to)
      Stackit.logger.info "Uploading #{artifact} to s3://#{bucket_name}/#{to}"
      File.open(artifact, 'rb') do |body|
        Stackit.aws.s3.put_object(
          bucket: bucket_name,
          key: to,
          body: body
        )
      end
    end

    def download(artifact, to)
      artifact_name = artifact.split('/').last
      to_path = "#{to}/#{artifact_name}"
      Stackit.logger.info "Downloading s3://#{bucket_name}/#{artifact} to #{to_path}"
      Stackit.aws.s3.get_object({
        bucket: bucket_name,
        key: artifact
      },
        target: to_path
      )
    end

  end
end