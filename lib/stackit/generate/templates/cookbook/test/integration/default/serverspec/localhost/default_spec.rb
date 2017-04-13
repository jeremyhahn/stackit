require 'spec_helper'

describe process("sshd") do
  it { should be_running }
  it "is listening on port 22" do
    expect(port(22)).to be_listening
  end
end
