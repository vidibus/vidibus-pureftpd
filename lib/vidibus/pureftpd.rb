module Vidibus
  module Pureftpd
    class Error < StandardError; end

    class << self

      # Default settings for Pure-FTPd.
      # You may overwrite settings like this:
      #   Vidibus::Pureftpd.settings[:sysuser] = 'desaster_master'
      def settings
        @settings ||= {
          :sysuser => 'pureftpd_user',
          :sysgroup => 'pureftpd_group',
          :password_file => '/etc/pure-ftpd/pureftpd.passwd'
        }
      end

      # Performs given command prefixed with pure-pw.
      # Accepts a block with |stdin, stdout, stderr|.
      def perform(cmd, &block)
        cmd = "pure-pw #{cmd}"
        error = ''
        output = nil

        pid, stdin, stdout, stderr = POSIX::Spawn::popen4(cmd)
        yield(stdin, stdout, stderr) if block_given?
        error = stderr.read
        output = stdout.read

        unless error == ''
          raise Error.new("Pure-FTPd returned an error:\n#{cmd}\n\n#{error}")
        end
        output
      ensure
        [stdin, stdout, stderr].each { |io| io.close if !io.closed? }
        Process::waitpid(pid)
      end
    end
  end
end
