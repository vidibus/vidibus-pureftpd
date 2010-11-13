module Vidibus # :nodoc
  module Pureftpd
    class Error < StandardError; end

    class << self

      # Default settings for Pure-FTPd.
      # You may overwrite settings like this:
      #   Vidibus::Pureftpd.settings[:sysuser] = "desaster_master"
      def settings
        @settings ||= {
          :sysuser => "pureftpd_user",
          :sysgroup => "pureftpd_group",
          :password_file => "/etc/pure-ftpd/pureftpd.passwd",
        }
      end

      # Adds a new user.
      # Required options:
      #   :login, :password, :directory
      def add_user(options)
        unless options.keys?(:login, :password, :directory)
          raise ArgumentError.new("Required options are :login, :password, :directory")
        end
        password = options.delete(:password)
        cmd = "pure-pw useradd %{login} -f %{password_file} -u %{sysuser} -g %{sysgroup} -d %{directory} -m" % settings.merge(options)
        perform(cmd) do |stdin, stdout, stderr|
          stdin.puts(password)
          stdin.puts(password)
        end
      end

      # Deletes an existing user.
      # Required options:
      #   :login
      def delete_user(options)
        unless options.key?(:login)
          raise ArgumentError.new("Required option is :login")
        end
        cmd = "pure-pw userdel %{login} -f %{password_file} -m" % settings.merge(options)
        perform(cmd)
      end

      # Changes password of existing user.
      # Required options:
      #   :login, :password
      def change_password(options)
        unless options.keys?(:login, :password)
          raise ArgumentError.new("Required options are :login, :password")
        end
        password = options.delete(:password)
        cmd = "pure-pw passwd %{login} -f %{password_file} -m" % settings.merge(options)
        perform(cmd) do |stdin, stdout, stderr|
          stdin.puts(password)
          stdin.puts(password)
        end
      end

      protected

      # Performs given command. Accepts a block with |stdin, stdout, stderr|.
      def perform(cmd, &block)
        error = ""
        Open3.popen3(cmd) do |stdin, stdout, stderr|
          yield(stdin, stdout, stderr) if block_given?
          error = stderr.read
        end
        unless error == ""
          raise Error.new("Error while executing this command:\n#{cmd}\n\n#{error}")
        end
      end
    end
  end
end
