# frozen_string_literal: true

require 'fileutils'
require 'pathname'

module Colore
  # The Colore Tika is a module to help with Tika-related configuration files.
  module TikaConfig
    # The configuration template version
    VERSION = 'v1'

    # The default language to use when the language has not been found
    DEFAULT_LANGUAGE = 'eng'

    # Config template
    TEMPLATE = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <properties>
        <parsers>
          <parser class="org.apache.tika.parser.DefaultParser"></parser>
          <parser class="org.apache.tika.parser.ocr.TesseractOCRParser">
            <params>
              <param name="language" type="string">%<language_alpha3>s</param>
            </params>
          </parser>
        </parsers>
      </properties>
    XML

    class << self
      private

      def tika_config_path
        Pathname.new File.expand_path(Colore::C_.tika_config_directory, __dir__)
      end

      def path_for!(language_alpha3)
        file = tika_config_path.join('ocr', VERSION, "tika.#{language_alpha3}.xml")
        return file if file.file?

        FileUtils.mkdir_p(tika_config_path.join('ocr', VERSION))
        File.write(file, format(TEMPLATE, language_alpha3: language_alpha3))
        file
      end
    end

    # Returns the file path of the Tika configuration for performing OCR
    # detection in a specified language.
    #
    # @param [String] language The language code in either ISO 639-1 (two-letter) or ISO 639-2 (three-letter) format.
    #                          Supported languages are those with corresponding Tika configuration files.
    #
    # @return [Pathname] The path to the Tika configuration file for the specified language or
    #                    the configuration file for DEFAULT_LANGUAGE if the language is not found.
    def self.path_for(language)
      language_alpha3 = Colore::Utils.language_alpha3(language) || DEFAULT_LANGUAGE

      path_for!(language_alpha3)
    end
  end
end
