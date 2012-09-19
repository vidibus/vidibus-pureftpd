require 'spec_helper'

describe Vidibus::Pureftpd::User do
  let(:attributes) do
    {
      :login => 'rspec_testuser',
      :password => 'secret',
      :directory => '/tmp/tester/'
    }
  end
  let(:new_user) { Vidibus::Pureftpd::User.new(attributes) }
  let(:existing_user) { Vidibus::Pureftpd::User.create(attributes) }

  before do
    Vidibus::Pureftpd.tap do |p|
      p.settings[:sysuser] = 'pureftpd_user'
      p.settings[:sysgroup] = 'pureftpd_group'
      p.settings[:password_file] = '/tmp/pureftpd_testing.passwd'
    end
    FileUtils.touch(Vidibus::Pureftpd.settings[:password_file])
  end

  after do
    FileUtils.rm(Vidibus::Pureftpd.settings[:password_file])
  end

  describe 'initializing' do
    it 'should work without attributes' do
      expect { Vidibus::Pureftpd::User.new }.
        not_to raise_error
    end

    it 'should set given attributes' do
      mock.any_instance_of(Vidibus::Pureftpd::User).attributes=(attributes)
      Vidibus::Pureftpd::User.new(attributes)
    end
  end

  describe 'validation' do
    it 'should pass with valid attributes' do
      new_user.should be_valid
    end

    it 'should fail without login' do
      new_user.login = nil
      new_user.should be_invalid
    end

    it 'should fail with invalid login' do
      new_user.login = 'some thing'
      new_user.should be_invalid
    end

    it 'should fail without a unique login' do
      new_user.login = existing_user.login
      new_user.should be_invalid
      new_user.errors.messages[:login].should eq(['has already been taken'])
    end

    it 'should fail without password' do
      new_user.password = nil
      new_user.should be_invalid
    end

    it 'should fail without directory' do
      new_user.directory = nil
      new_user.should be_invalid
    end

    context 'with a directory' do
      before do
        new_user.directory = '/whatever'
      end

      context 'that does not exist' do
        before do
          stub(File).exist?(new_user.directory) { false }
        end

        it 'should fail' do
          new_user.should be_invalid
          new_user.errors.messages[:directory].should eq(['does not exist'])
        end
      end

      context 'that does exist' do
        before do
          stub(File).exist?(new_user.directory) { true }
        end

        context 'but that is not a directory' do
          before do
            stub(File).directory?(new_user.directory) { false }
          end

          it 'should fail' do
            new_user.should be_invalid
            new_user.errors.messages[:directory].
              should eq(['must be a directory'])
          end
        end

        context 'and that is a directory' do
          before do
            stub(File).directory?(new_user.directory) { true }
          end

          context 'but is not readable' do
            before do
              stub(File).readable?(new_user.directory) { false }
            end

            it 'should fail' do
              new_user.should be_invalid
              new_user.errors.messages[:directory].
                should eq(['must be readable'])
            end
          end

          context 'and is readable' do
            before do
              stub(File).readable?(new_user.directory) { true }
            end

            context 'but that is not writable' do
              before do
                stub(File).writable?(new_user.directory) { false }
              end

              it 'should fail' do
                new_user.should be_invalid
                new_user.errors.messages[:directory].
                  should eq(['must be writable'])
              end
            end
          end
        end
      end
    end
  end

  describe '#login' do
    it 'should be accessible' do
      new_user.login = 'whatever'
      new_user.login.should eq('whatever')
    end
  end

  describe '#password' do
    it 'should be accessible' do
      new_user.password = 'whatever'
      new_user.password.should eq('whatever')
    end

    it 'should be encrypted when reading from a persisted instance' do
      existing_user.reload.password.should_not eq('whatever')
    end
  end

  describe '#directory' do
    it 'should be accessible' do
      new_user.directory = 'whatever'
      new_user.directory.should eq('whatever')
    end
  end

  describe '#attributes' do
    it 'should be a hash of current attributes' do
      new_user.attributes.should eq(attributes)
    end
  end

  describe '#attributes=' do
    it 'should set attributes on instance' do
      new_user.attributes = {
        :login => 'this',
        :password => 'is',
        :directory => 'new'
      }
      new_user.login.should eq('this')
      new_user.password.should eq('is')
      new_user.directory.should eq('new')
    end

    it 'should raise an error for unsupported attributes' do
      expect { new_user.attributes = {:whatever => 'wrong'} }.
        to raise_error(NoMethodError)
    end
  end

  describe '#save' do
    context 'on a new instance' do
      context 'with valid attributes' do
        it 'should add a new user' do
          new_user.save
          Vidibus::Pureftpd::User.find_by_login(new_user.login).
            should_not be_nil
        end

        it 'should return true' do
          new_user.save.should be_true
        end
      end

      context 'with invalid attributes' do
        let(:attributes) do
          {:login => nil}
        end

        it 'should not add a new user' do
          new_user.save
          Vidibus::Pureftpd::User.find_by_login(new_user.login).
            should be_nil
        end

        it 'should return false' do
          new_user.save.should be_false
        end
      end
    end

    context 'on an existing instance' do
      context 'with valid attributes' do
        context 'which are all unchanged' do
          it 'should not perform an update' do
            dont_allow(existing_user).perform
            existing_user.save
          end

          it 'should return true' do
            new_user.save.should be_true
          end
        end

        context 'with changed login' do
          before do
            existing_user.login = 'something_new'
          end

          it 'should destroy the old user' do
            old_login = existing_user.login_was
            existing_user.save
            Vidibus::Pureftpd::User.find_by_login(old_login).should be_nil
          end

          it 'should create a new user with identical attributes' do
            existing_user.save
            user = Vidibus::Pureftpd::User.find_by_login(existing_user.login)
            user.should be_a(Vidibus::Pureftpd::User)
            user.login.should eq(existing_user.login)
            user.directory.should eq(existing_user.directory + './')
          end

          it 'should return true' do
            existing_user.save.should be_true
          end

          # Double check uniqueness check because we don't rely on ids
          it 'should fail if login is taken' do
            user = Vidibus::Pureftpd::User.create(attributes.merge(:login => existing_user.login))
            dont_allow(existing_user).destroy
            existing_user.save.should be_false
          end
        end

        context 'with changed password' do
          before do
            existing_user.password = 'something new'
          end

          it 'should store the new password' do
            user = Vidibus::Pureftpd::User.find_by_login(existing_user.login)
            old_password = user.password
            existing_user.save
            user = Vidibus::Pureftpd::User.find_by_login(existing_user.login)
            user.password.should_not eq(old_password)
          end

          it 'should return true' do
            existing_user.save.should be_true
          end
        end

        context 'with changed directory' do
          before do
            existing_user.directory = '/tmp/different'
            mock(existing_user).valid_directory? { true }
          end

          it 'should store the new directory' do
            existing_user.save
            user = Vidibus::Pureftpd::User.find_by_login(existing_user.login)
            user.directory.should eq('/tmp/different/./')
          end

          it 'should return true' do
            existing_user.save.should be_true
          end
        end
      end

      context 'with invalid attributes' do
        before do
          existing_user.login = nil
        end

        it 'should not perform an update' do
          dont_allow(existing_user).perform
          existing_user.save
        end

        it 'should return false' do
          existing_user.save.should be_false
        end
      end
    end
  end

  describe '#destroy' do
    context 'on an existing user' do
      it 'should destroy it' do
        existing_user.destroy
        Vidibus::Pureftpd::User.find_by_login(existing_user.login).
          should be_nil
      end

      it 'should destroy it even with changed login' do
        login = existing_user.login
        existing_user.login = 'changed_login'
        existing_user.destroy
        Vidibus::Pureftpd::User.find_by_login(login).
          should be_nil
      end

      it 'should return the user record nonetheless' do
        existing_user.destroy.should be_a(Vidibus::Pureftpd::User)
      end

      it 'should flag the user as not persisted' do
        existing_user.destroy
        existing_user.persisted?.should be_false
      end
    end

    context 'on a new user' do
      it 'should return false' do
        new_user.destroy.should be_false
      end

      it 'should not destroy anything' do
        dont_allow(new_user).perform
        new_user.destroy
      end
    end
  end

  describe '#reload' do
    context 'on an existing user' do
      it 'should return the user' do
        existing_user.reload.should be_a(Vidibus::Pureftpd::User)
      end

      it 'should reload attributes' do
        old_login = existing_user.login
        existing_user.login = 'something_new'
        existing_user.reload.login.should eq(old_login)
      end
    end

    context 'on a new user' do
      it 'should raise an error' do
        expect { new_user.reload }.
          to raise_error(Vidibus::Pureftpd::User::DocumentNotFound)
      end
    end

  end

  describe '.find_by_login' do
    it 'should require an attribute' do
      expect { Vidibus::Pureftpd::User.find_by_login }.
        to raise_error(ArgumentError)
    end

    it 'should return nil if no user matches given login' do
      Vidibus::Pureftpd::User.find_by_login('whatever').should be_nil
    end

    it 'should re-raise arbitrary Pure-FTPd errors' do
      mock(Vidibus::Pureftpd).perform.with_any_args do
        raise Vidibus::Pureftpd::Error.new('something went wrong')
      end
      expect { Vidibus::Pureftpd::User.find_by_login('whatever') }.
        to raise_error(Vidibus::Pureftpd::Error, 'something went wrong')
    end

    context 'with existing user' do
      before do
        existing_user
      end

      it 'should return a user instance with matching login' do
        user = Vidibus::Pureftpd::User.find_by_login('rspec_testuser')
        user.should be_a(Vidibus::Pureftpd::User)
      end

      it 'should populate attributes' do
        user = Vidibus::Pureftpd::User.find_by_login('rspec_testuser')
        user.login.should eq(attributes[:login])
        user.password.should_not match(attributes[:password]) # is encrypted
        user.directory.should eq(attributes[:directory] + './')
      end
    end
  end

  describe '.create' do
    it 'should require attributes' do
      expect { Vidibus::Pureftpd::User.create }.
        to raise_error(ArgumentError)
    end

    context 'with valid attributes' do
      it 'should return a valid instance' do
        user = Vidibus::Pureftpd::User.create(attributes)
        user.should be_a(Vidibus::Pureftpd::User)
        user.should be_valid
      end

      it 'should create a new user' do
        Vidibus::Pureftpd::User.create(attributes)
        Vidibus::Pureftpd::User.find_by_login('rspec_testuser').
          should be_a(Vidibus::Pureftpd::User)
      end
    end

    context 'with invalid attributes' do
      let(:attributes) do
        {:login => nil}
      end

      it 'should return a new user object with errors' do
        user = Vidibus::Pureftpd::User.create(attributes)
        user.should be_a(Vidibus::Pureftpd::User)
        user.should be_invalid
      end

      it 'should not create a new instance' do
        Vidibus::Pureftpd::User.create(attributes)
        Vidibus::Pureftpd::User.find_by_login('rspec_testuser').should be_nil
      end
    end
  end
end
