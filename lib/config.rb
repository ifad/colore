# frozen_string_literal: true

require 'erb'
require 'pathname'
require 'yaml'

Encoding.default_internal = 'UTF-8'
Encoding.default_external = 'UTF-8'

module Colore
  #
  # This is a simple mechanism to hold document configuration. A future version will replace
  # this with SimpleConfig.
  #
  # It is accessed by calling C_.{config setting}, where the config settings are
  # defined as attr_accessors in the class. For example:
  #
  #   storage_dir = C_.storage_directory
  #
  class C_
    # @return [String] Base storage directory for all documents
    attr_accessor :storage_directory
    # @return [String] File URL base for legacy convert API method
    attr_accessor :legacy_url_base
    # @return [Integer] Number of days to keep legacy files before purging
    attr_accessor :legacy_purge_days
    # @return [String] Redis configuration (used by sidekiq)
    attr_accessor :redis
    # @return [String] Path to the Heathen conversion log
    attr_accessor :conversion_log
    # @return [String] Path to the Error log
    attr_accessor :error_log

    # @return [String] Path to the convert executable. Defaults to `"convert"`
    attr_accessor :convert_path
    # @return [String] Path to the libreoffice executable. Defaults to `"libreoffice"`
    attr_accessor :libreoffice_path
    # @return [String] Path to the tesseract executable. Defaults to `"tesseract"`
    attr_accessor :tesseract_path
    # @return [String] Path to the tika executable. Defaults to `"tika"`
    attr_accessor :tika_path
    # @return [String] Path to the wkhtmltopdf binary. Defaults to `"wkhtmltopdf"`
    attr_accessor :wkhtmltopdf_path
    # @return [String] Relative path to the writable tika config directory. Defaults to `"../tmp/tika"`
    attr_accessor :tika_config_directory
    # @return [String] Params for wkhtmltopdf
    attr_accessor :wkhtmltopdf_params
    # @return [Boolean] Enable mock documents for development when document not found
    attr_accessor :mock_documents_enabled
    # @return [String] Current environment (development, test, production, staging)
    attr_accessor :environment

    def self.config_file_path
      Pathname.new File.expand_path('../config/app.yml', __dir__)
    end

    def self.config
      @config ||= begin
        c = new
        yaml = load_yaml_config
        load_core_config(c, yaml)
        load_tool_paths(c, yaml)
        load_additional_config(c, yaml)
        load_environment_config(c, yaml)
        c
      end
    end

    def self.method_missing(*args)
      if config.respond_to? args[0].to_sym
        config.send(*args)
      else
        super
      end
    end

    # Reset config - used for testing
    def self.reset
      @config = nil
    end

    # Private helper methods
    class << self
      private

      def load_yaml_config
        template = ERB.new(config_file_path.read)
        YAML.load(template.result)
      end

      def load_core_config(config, yaml)
        config.storage_directory = yaml['storage_directory']
        config.legacy_url_base = yaml['legacy_url_base']
        config.legacy_purge_days = yaml['legacy_purge_days'].to_i
        config.redis = yaml['redis']
        config.conversion_log = yaml['conversion_log']
        config.error_log = yaml['error_log']
      end

      def load_tool_paths(config, yaml)
        config.convert_path = yaml['convert_path'] || 'convert'
        config.libreoffice_path = yaml['libreoffice_path'] || 'libreoffice'
        config.tesseract_path = yaml['tesseract_path'] || 'tesseract'
        config.tika_path = yaml['tika_path'] || 'tika'
        config.wkhtmltopdf_path = yaml['wkhtmltopdf_path'] || 'wkhtmltopdf'
      end

      def load_additional_config(config, yaml)
        config.tika_config_directory = yaml['tika_config_directory'] || '../tmp/tika'
        config.wkhtmltopdf_params = yaml['wkhtmltopdf_params'] || ''
      end

      def load_environment_config(config, yaml)
        config.environment = ENV['RACK_ENV'] || 'development'
        mock_enabled = yaml['mock_documents_enabled'] || false
        # In production, always disable mocks regardless of config
        config.mock_documents_enabled = config.environment == 'production' ? false : mock_enabled
      end
    end
  end
end
