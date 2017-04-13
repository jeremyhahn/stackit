module Stackit
  class Artifact < Bucket

    attr_accessor :artifact_name
    attr_accessor :artifact_path

    def initialize(name, path)
      self.artifact_name = name
      self.artifact_path = path
    end

    def upload(to = default_artifact_repo)
      Stackit.logger.debug "Uploading #{artifact_name} to #{to}"
      super(artifact_path, to)
    end

    def download(to = '.')
      Stackit.logger.debug "Downloading #{artifact_name} to #{to}"
      super(artifact_path, to)
    end

  private

    def default_artifact_repo
      Stackit.configuration[Stackit.environment][:default_artifact_repo]
    end

  end
end