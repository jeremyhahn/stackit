require_relative 'instance'

module Stackit::Mixin::Ssh

  include Stackit::Mixin::Instance

  def ssh_username
    options[:ssh_username] || environment_config[:default_ssh_username]
  end

  def ssh_keypair
    options[:ssh_keypair] || environment_config[:default_ssh_keypair]
  end

  def ssh_private_key
    options[:ssh_private_key] || environment_config[:default_ssh_private_key]
  end

  def ssh_exec(cmd)
    Stackit.logger.debug "Executing remote SSH command. host=#{instance_private_ip}, command=#{cmd}"
    result = Stackit::Shellout.ssh_run(instance_private_ip, cmd, ssh_username, {
      :host_key => "ssh-rsa",
      :encryption => "blowfish-cbc",
      :keys => [ssh_private_key],
      :compression => "zlib@openssh.com"
    })
    Stackit.logger.debug result
    result[:data]
  end

  def ssh_sudo_exec(user, cmd)
    Stackit.logger.debug "Executing remote SSH sudo command. host=#{instance_private_ip}, command=#{cmd}, user=#{user}"
    result = ssh_exec(instance_private_ip, "sudo su #{user} -c '#{cmd}'", ssh_username, {
      :host_key => "ssh-rsa",
      :encryption => "blowfish-cbc",
      :keys => [ssh_key],
      :compression => "zlib@openssh.com"
    })
    Stackit.logger.debug result
    result[:data]
  end

end
