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
              <param name="language" type="string">%<alpha3_languages>s</param>
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

      def path_for!(alpha3_languages)
        file = tika_config_path.join('ocr', VERSION, "tika.#{alpha3_languages.sort.join('-')}.xml")
        return file if file.file?

        FileUtils.mkdir_p(tika_config_path.join('ocr', VERSION))
        file.write format(TEMPLATE, alpha3_languages: alpha3_languages.join('+'))
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

      path_for!([language_alpha3])
    end

    # Returns the file path of the Tika configuration for performing language
    # detection.
    #
    # @return [Pathname] The path to the Tika configuration file for language detection
    def self.path_for_language_detection
      path_for!(Colore::C_.tesseract_available_languages)
    end
  end
end
