# frozen_string_literal: true

begin
  require 'vagrant'
rescue LoadError
  raise 'The Vagrant Packet plugin must be run within Vagrant.'
end

# This is a sanity check to make sure no one is attempting to install
# this into an early Vagrant version.
raise 'The Vagrant Packet plugin is only compatible with Vagrant 1.2+' if Vagrant::VERSION < '1.2.0'

module VagrantPlugins
  module Packet
    class Plugin < Vagrant.plugin('2')
      name 'Packet'
      description <<-DESC
      This plugin installs a provider that allows Vagrant to manage
      machines in Packet.
      DESC

      config(:packet, :provider) do
        require_relative 'config'
        Config
      end

      provider(:packet, parallel: true) do
        # Setup logging and i18n
        setup_logging
        setup_i18n

        # Return the provider
        require_relative 'provider'
        Provider
      end

      # This initializes the internationalization strings.
      def self.setup_i18n
        I18n.load_path << File.expand_path('locales/en.yml', Packet.source_root)
        I18n.reload!
      end

      # This sets up our log level to be whatever VAGRANT_LOG is.
      def self.setup_logging
        require 'log4r'

        level = nil
        begin
          level = Log4r.const_get(ENV['VAGRANT_LOG'].upcase)
        rescue NameError
          # This means that the logging constant wasn't found,
          # which is fine. We just keep `level` as `nil`. But
          # we tell the user.
          level = nil
        end

        # Some constants, such as 'true' resolve to booleans, so the
        # above error checking doesn't catch it. This will check to make
        # sure that the log level is an integer, as Log4r requires.
        level = nil unless level.is_a?(Integer)
        return unless level
        # Set the logging level on all 'vagrant' namespaced
        # logs as long as we have a valid level.
        logger = Log4r::Logger.new('vagrant_packet')
        logger.outputters = Log4r::Outputter.stderr
        logger.level = level
        logger = nil # rubocop:disable Lint/UselessAssignment
      end
    end
  end
end
