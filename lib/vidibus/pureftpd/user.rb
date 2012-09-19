module Vidibus
  module Pureftpd
    class User
      include ActiveModel::Validations
      include ActiveModel::Dirty

      class Error < Vidibus::Pureftpd::Error; end
      class DocumentNotFound < Error; end

      ACCESSSORS = [:login, :password, :directory]

      ACCESSSORS.each do |attribute|
        class_eval <<-EOS
          def #{attribute}=(value)
            unless @#{attribute} == value
              #{attribute}_will_change!
              @#{attribute} = value
            end
          end

          def #{attribute}
            @#{attribute}
          end
        EOS
      end

      define_attribute_methods ACCESSSORS

      validates :password, :directory, :presence => true
      validates :login, :format => { :with => /^[a-z_]+$/ }
      validate :unique_login?, :if => :login_changed?
      validate :valid_directory?, :if => :directory_changed?

      def initialize(values = {})
        self.attributes = values
        @persisted = false
      end

      def save
        return false unless valid? && changed?
        persisted? ? update : create
        @previously_changed = changes
        @changed_attributes.clear
        @persisted = true
      end

      def destroy
        return false unless persisted? && login_was
        cmd = "userdel #{login_was} -f %{password_file} -m" % settings
        perform(cmd)
        instance_variable_set('@persisted', false)
        self
      end

      def persisted?
        @persisted
      end

      def attributes
        hash = {}
        [:login, :password, :directory].each do |a|
          hash[a] = send(a)
        end
        hash
      end

      def attributes=(hash)
        hash.each do |key, value|
          send("#{key}=", value)
        end
      end

      def reload
        if persisted? && login_was && (user = User.find_by_login(login_was))
          self.attributes = user.attributes
          self
        else
          raise DocumentNotFound
        end
      end

      class << self

        def find_by_login(login)
          cmd = "show #{login} -f %{password_file}" %
            Vidibus::Pureftpd.settings
          begin
            data = Vidibus::Pureftpd.perform(cmd)
          rescue Vidibus::Pureftpd::Error => e
            if e.message.match('Unable to fetch info about user')
              return nil
            else
              raise e
            end
          end

          attributes = {}
          data.scan(/(#{ACCESSSORS.join('|')})\s*:\s*(.+)/i).each do |key, value|
            attributes[key.downcase] = value
          end

          User.new(attributes).tap do |user|
            user.instance_variable_set('@persisted', true)
          end
        end

        def create(attributes)
          new(attributes).tap do |user|
            user.save
          end
        end
      end

      private

      def settings
        attributes.merge(Vidibus::Pureftpd.settings)
      end

      def unique_login?
        return unless login.present?
        if User.find_by_login(login)
          self.errors.add(:login, :taken)
        end
      end

      def valid_directory?
        return unless directory.present?
        if !File.exist?(directory)
          self.errors.add(:directory, :not_existent)
        elsif !File.directory?(directory)
          self.errors.add(:directory, :not_a_directory)
        elsif !File.readable?(directory)
          self.errors.add(:directory, :not_readable)
        elsif !File.writable?(directory)
          self.errors.add(:directory, :not_writable)
        end
      end

      def update
        if login_changed?
          a = attributes
          destroy
          User.create(a)
        end
        if password_changed?
          update_password
        end
        if changes.except(:login, :password).any?
          update_attributes
        end
      end

      def create
        cmd = 'useradd %{login} -f %{password_file} -u %{sysuser} -g %{sysgroup} -d %{directory} -m' % settings
        perform_with_password_input(cmd)
      end

      def update_password
        cmd = 'passwd %{login} -f %{password_file} -m' % settings
        perform_with_password_input(cmd)
      end

      def update_attributes
        cmd = 'usermod %{login} -d %{directory} -f %{password_file} -m' % settings
        perform(cmd)
      end

      # TODO: Dry this up. But args << &Proc.new isn't possible.
      def perform(cmd)
        if block_given?
          Vidibus::Pureftpd.perform(cmd, &Proc.new)
        else
          Vidibus::Pureftpd.perform(cmd)
        end
      end

      def perform_with_password_input(cmd)
        perform(cmd) do |stdin, stdout, stderr|
          stdin.puts(password)
          stdin.puts(password)
        end
      end
    end
  end
end
