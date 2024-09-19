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
    # Base storage directory for all documents
    attr_accessor :storage_directory
    # File URL base for legacy convert API method
    attr_accessor :legacy_url_base
    # Number of days to keep legacy files before purging
    attr_accessor :legacy_purge_days
    # Redis configuration (used by sidekiq)
    attr_accessor :redis
    # Path to the Heathen conversion log
    attr_accessor :conversion_log
    # Path to the Error log
    attr_accessor :error_log

    # Path to the convert executable
    attr_accessor :convert_path
    # Path to the libreoffice executable
    attr_accessor :libreoffice_path
    # Path to the tesseract executable
    attr_accessor :tesseract_path
    # Path to the tika executable
    attr_accessor :tika_path
    # Path to the wkhtmltopdf binary
    attr_accessor :wkhtmltopdf_path
    # Params for wkhtmltopdf
    attr_accessor :wkhtmltopdf_params

    def self.config_file_path
      Pathname.new File.expand_path('../config/app.yml', __dir__)
    end

    def self.config
      @config ||= begin
        template = ERB.new(config_file_path.read)
        yaml = YAML.load(template.result)
        c = new
        c.storage_directory = yaml['storage_directory']
        c.legacy_url_base = yaml['legacy_url_base']
        c.legacy_purge_days = yaml['legacy_purge_days'].to_i
        c.redis = yaml['redis']
        c.conversion_log = yaml['conversion_log']
        c.error_log = yaml['error_log']

        c.convert_path = yaml['convert_path'] || 'convert'
        c.libreoffice_path = yaml['libreoffice_path'] || 'libreoffice'
        c.tesseract_path = yaml['tesseract_path'] || 'tesseract'
        c.tika_path = yaml['tika_path'] || 'tika'
        c.wkhtmltopdf_path = yaml['wkhtmltopdf_path'] || 'wkhtmltopdf'
        c.wkhtmltopdf_params = yaml['wkhtmltopdf_params'] || ''

        c
      end
    end

    def self.method_missing *args
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
  end
end
