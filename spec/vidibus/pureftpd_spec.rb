require 'spec_helper'

describe 'Vidibus::Pureftpd' do
  let(:pureftpd) do
    Vidibus::Pureftpd.tap do |p|
      p.settings[:sysuser] = 'pureftpd_user'
      p.settings[:sysgroup] = 'pureftpd_group'
    end
  end

  let(:login) { 'pureftpd_tester' }
  let(:password) { 'secret' }
  let(:directory) { '/tmp/tester' }

  def setup
    pureftpd.add_user(:login => login, :password => password, :directory => directory)
  rescue
  end

  def teardown
    pureftpd.delete_user(:login => login)
  rescue
  end

  describe '.add_user' do
    it 'should raise an error unless all required options are given' do
      expect { pureftpd.add_user(:login => login, :password => password) }.to raise_error(ArgumentError)
    end

    it 'should add a new ftp user' do
      pureftpd.add_user({
        :login => login,
        :password => password,
        :directory => directory
      }).should be_true
    end

    it 'should raise an error if user already exists' do
      pureftpd.add_user(:login => login, :password => password, :directory => directory)
      expect { pureftpd.add_user({
        :login => login,
        :password => password,
        :directory => directory}) }.to raise_error(Vidibus::Pureftpd::Error)
    end

    after { teardown }
  end

  describe '.delete_user' do
    before { setup }

    it 'should raise an error unless all required options are given' do
      expect { pureftpd.delete_user }.to raise_error(ArgumentError)
    end

    it 'should delete an existing ftp user' do
      pureftpd.delete_user(:login => login).should be_true
    end

    it 'should raise an error if user does not exist' do
      pureftpd.delete_user(:login => login)
      expect { pureftpd.delete_user(:login => login) }.
        to raise_error(Vidibus::Pureftpd::Error)
    end
  end

  describe '.change_password' do
    it 'should raise an error unless all required options are given' do
      expect { pureftpd.change_password(:login => login) }.
        to raise_error(ArgumentError)
    end

    it 'should change the password of an existing ftp user' do
      setup
      pureftpd.change_password(:login => login, :password => password)
      teardown
    end

    it 'should raise an error if user does not exist' do
      expect { pureftpd.change_password({
        :login => login,
        :password => password}) }.to raise_error(Vidibus::Pureftpd::Error)
    end
  end
end
