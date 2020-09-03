require 'spec_helper'

describe Puppet::Util::RunMode do
  before do
    @run_mode = Puppet::Util::RunMode.new('fake')
  end

  describe Puppet::Util::UnixRunMode, :unless => Puppet::Util::Platform.windows? do
    before do
      @run_mode = Puppet::Util::UnixRunMode.new('fake')
    end

    describe "#conf_dir" do
      it "has confdir /etc/puppetlabs/puppet when run as root" do
        as_root { expect(@run_mode.conf_dir).to eq(File.expand_path('/etc/puppetlabs/puppet')) }
      end

      it "has confdir ~/.puppetlabs/etc/puppet when run as non-root" do
        as_non_root { expect(@run_mode.conf_dir).to eq(File.expand_path('~/.puppetlabs/etc/puppet')) }
      end

      context "master run mode" do
        before do
          @run_mode = Puppet::Util::UnixRunMode.new('master')
        end

        it "has confdir ~/.puppetlabs/etc/puppet when run as non-root and master run mode" do
          as_non_root { expect(@run_mode.conf_dir).to eq(File.expand_path('~/.puppetlabs/etc/puppet')) }
        end
      end
    end

    describe "#code_dir" do
      it "has codedir /etc/puppetlabs/code when run as root" do
        as_root { expect(@run_mode.code_dir).to eq(File.expand_path('/etc/puppetlabs/code')) }
      end

      it "has codedir ~/.puppetlabs/etc/code when run as non-root" do
        as_non_root { expect(@run_mode.code_dir).to eq(File.expand_path('~/.puppetlabs/etc/code')) }
      end

      context "master run mode" do
        before do
          @run_mode = Puppet::Util::UnixRunMode.new('master')
        end

        it "has codedir ~/.puppetlabs/etc/code when run as non-root and master run mode" do
          as_non_root { expect(@run_mode.code_dir).to eq(File.expand_path('~/.puppetlabs/etc/code')) }
        end
      end
    end

    describe "#var_dir" do
      it "has vardir /opt/puppetlabs/puppet/cache when run as root" do
        as_root { expect(@run_mode.var_dir).to eq(File.expand_path('/opt/puppetlabs/puppet/cache')) }
      end

      it "has vardir ~/.puppetlabs/opt/puppet/cache when run as non-root" do
        as_non_root { expect(@run_mode.var_dir).to eq(File.expand_path('~/.puppetlabs/opt/puppet/cache')) }
      end
    end

    describe "#public_dir" do
      it "has publicdir /opt/puppetlabs/puppet/public when run as root" do
        as_root { expect(@run_mode.public_dir).to eq(File.expand_path('/opt/puppetlabs/puppet/public')) }
      end

      it "has publicdir ~/.puppetlabs/opt/puppet/public when run as non-root" do
        as_non_root { expect(@run_mode.public_dir).to eq(File.expand_path('~/.puppetlabs/opt/puppet/public')) }
      end
    end

    describe "#log_dir" do
      describe "when run as root" do
        it "has logdir /var/log/puppetlabs/puppet" do
          as_root { expect(@run_mode.log_dir).to eq(File.expand_path('/var/log/puppetlabs/puppet')) }
        end
      end

      describe "when run as non-root" do
        it "has default logdir ~/.puppetlabs/var/log" do
          as_non_root { expect(@run_mode.log_dir).to eq(File.expand_path('~/.puppetlabs/var/log')) }
        end
      end
    end

    describe "#run_dir" do
      describe "when run as root" do
        it "has rundir /var/run/puppetlabs" do
          as_root { expect(@run_mode.run_dir).to eq(File.expand_path('/var/run/puppetlabs')) }
        end
      end

      describe "when run as non-root" do
        it "has default rundir ~/.puppetlabs/var/run" do
          as_non_root { expect(@run_mode.run_dir).to eq(File.expand_path('~/.puppetlabs/var/run')) }
        end
      end
    end
  end

  describe Puppet::Util::WindowsRunMode, :if => Puppet::Util::Platform.windows? do
    before do
      @run_mode = Puppet::Util::WindowsRunMode.new('fake')
    end

    describe "#conf_dir" do
      it "has confdir ending in Puppetlabs/puppet/etc when run as root" do
        as_root { expect(@run_mode.conf_dir).to eq(File.expand_path(File.join(ENV['ALLUSERSPROFILE'], "PuppetLabs", "puppet", "etc"))) }
      end

      it "has confdir in ~/.puppetlabs/etc/puppet when run as non-root" do
        as_non_root { expect(@run_mode.conf_dir).to eq(File.expand_path("~/.puppetlabs/etc/puppet")) }
      end
    end

    describe "#code_dir" do
      it "has codedir ending in PuppetLabs/code when run as root" do
        as_root { expect(@run_mode.code_dir).to eq(File.expand_path(File.join(ENV['ALLUSERSPROFILE'], "PuppetLabs", "code"))) }
      end

      it "has codedir in ~/.puppetlabs/etc/code when run as non-root" do
        as_non_root { expect(@run_mode.code_dir).to eq(File.expand_path("~/.puppetlabs/etc/code")) }
      end
    end

    describe "#var_dir" do
      it "has vardir ending in PuppetLabs/puppet/cache when run as root" do
        as_root { expect(@run_mode.var_dir).to eq(File.expand_path(File.join(ENV['ALLUSERSPROFILE'], "PuppetLabs", "puppet", "cache"))) }
      end

      it "has vardir in ~/.puppetlabs/opt/puppet/cache when run as non-root" do
        as_non_root { expect(@run_mode.var_dir).to eq(File.expand_path("~/.puppetlabs/opt/puppet/cache")) }
      end
    end

    describe "#public_dir" do
      it "has publicdir ending in PuppetLabs/puppet/public when run as root" do
        as_root { expect(@run_mode.public_dir).to eq(File.expand_path(File.join(ENV['ALLUSERSPROFILE'], "PuppetLabs", "puppet", "public"))) }
      end

      it "has publicdir in ~/.puppetlabs/opt/puppet/public when run as non-root" do
        as_non_root { expect(@run_mode.public_dir).to eq(File.expand_path("~/.puppetlabs/opt/puppet/public")) }
      end
    end

    describe "#log_dir" do
      describe "when run as root" do
        it "has logdir ending in PuppetLabs/puppet/var/log" do
          as_root { expect(@run_mode.log_dir).to eq(File.expand_path(File.join(ENV['ALLUSERSPROFILE'], "PuppetLabs", "puppet", "var", "log"))) }
        end
      end

      describe "when run as non-root" do
        it "has default logdir ~/.puppetlabs/var/log" do
          as_non_root { expect(@run_mode.log_dir).to eq(File.expand_path('~/.puppetlabs/var/log')) }
        end
      end
    end

    describe "#run_dir" do
      describe "when run as root" do
        it "has rundir ending in PuppetLabs/puppet/var/run" do
          as_root { expect(@run_mode.run_dir).to eq(File.expand_path(File.join(ENV['ALLUSERSPROFILE'], "PuppetLabs", "puppet", "var", "run"))) }
        end
      end

      describe "when run as non-root" do
        it "has default rundir ~/.puppetlabs/var/run" do
          as_non_root { expect(@run_mode.run_dir).to eq(File.expand_path('~/.puppetlabs/var/run')) }
        end
      end
    end

    describe "#without_env internal helper with UTF8 characters" do
      let(:varname) { "\u16A0\u16C7\u16BB\u16EB\u16D2\u16E6\u16A6\u16EB\u16A0\u16B1\u16A9\u16A0\u16A2\u16B1\u16EB\u16A0\u16C1\u16B1\u16AA\u16EB\u16B7\u16D6\u16BB\u16B9\u16E6\u16DA\u16B3\u16A2\u16D7" }
      let(:rune_utf8) { "\u16A0\u16C7\u16BB\u16EB\u16D2\u16E6\u16A6\u16EB\u16A0\u16B1\u16A9\u16A0\u16A2\u16B1\u16EB\u16A0\u16C1\u16B1\u16AA\u16EB\u16B7\u16D6\u16BB\u16B9\u16E6\u16DA\u16B3\u16A2\u16D7" }

      before do
        Puppet::Util::Windows::Process.set_environment_variable(varname, rune_utf8)
      end

      it "removes environment variables within the block with UTF8 name" do
        without_env(varname) do
          expect(ENV[varname]).to be(nil)
        end
      end

      it "restores UTF8 characters in environment variable values" do
        without_env(varname) do
          Puppet::Util::Windows::Process.set_environment_variable(varname, 'bad value')
        end

        envhash = Puppet::Util::Windows::Process.get_environment_strings
        expect(envhash[varname]).to eq(rune_utf8)
      end
    end
  end

  def as_root
    allow(Puppet.features).to receive(:root?).and_return(true)
    yield
  end

  def as_non_root
    allow(Puppet.features).to receive(:root?).and_return(false)
    yield
  end

  def without_env(name, &block)
    saved = Puppet::Util.get_env(name)
    Puppet::Util.set_env(name, nil)
    yield
  ensure
    Puppet::Util.set_env(name, saved)
  end
end
