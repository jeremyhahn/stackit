require 'mixlib/shellout'
require 'net/ssh'

module Stackit
  class Shellout

    def self.run(command, cwd = '.', stream = STDOUT)
      shellout = ::Mixlib::ShellOut.new(
        command,
        live_stream: stream,
        logger: Stackit.logger,
        cwd: cwd
      )
      shellout.run_command
      shellout.stdout
    end

    def self.exec(command, cwd = '.', stream = STDOUT)
      shellout = ::Mixlib::ShellOut.new(
        command,
        live_stream: stream,
        logger: Stackit.logger,
        cwd: cwd
      )
      shellout.run_command
      shellout.exitstatus
    end

    def self.ssh_exec(ip_address, commands, ssh_user, options)
      response = {
        :data => "",
        :stdout => "",
        :stderr => "",
        :code => nil,
        :signal => nil
      }
      Net::SSH.start(ip_address, ssh_user, options) do |ssh|
        ssh.open_channel do |channel|
          channel.request_pty do |ch, success|
            raise 'Unable to obtain pty during ssh connection' unless success
            Stackit.logger.debug "SSH connection successful"
          end
          channel.exec(commands) do |ch, success|
            abort "Could not execute commands!" unless success
            channel.on_data do |ch, data|
              response[:data] += "#{data}"
            end
            channel.on_extended_data do |ch, data|
              response[:stderr] += "#{data}"
            end
            channel.on_request("exit-status") do |ch, data|
              response[:code] = data.read_long
            end
            channel.on_request("exit-signal") do |ch, data|
              response[:signal] = data.read_long
            end
            channel.on_close do |ch|
              Stackit.logger.debug "Closing SSH connection"
            end
          end
        end
        ssh.loop
      end
      if response[:code] > 0
        raise response[:data] if response[:data]
        raise response[:stdout] if response[:stdout]
      end
      raise response[:stderr] unless response[:stderr].empty?
      response
    end

  end
end
