# frozen_string_literal: true

module Heathen
  class Processor
    # Performs OCR on the input document, which must be in TIFF format. Calls the 'tesseract'
    # program to achieve this.
    # @param: format - output format. Possibilities are nil, hocr and pdf
    #                  nil creates a text version
    #                  hocr creates a .hocr XML file preserving letter position
    #                  pdf creates a .pdf file, consisting of the image backed by the text.
    def tesseract(format: nil)
      expect_mime_type 'image/tiff'

      # Lookup the ISO 639-2 (alpha-3) language object required by Tesseract
      language_alpha3 = Colore::Utils.language_alpha3(job.language)
      raise InvalidLanguageInStep.new(job.language) if language_alpha3.nil?

      target_file = temp_file_name
      executioner.execute(
        Colore::C_.tesseract_path,
        job.content_file,
        target_file,
        '-l', language_alpha3,
        format
      )
      raise ConversionFailed.new(executioner.last_messages) if executioner.last_exit_status != 0

      suffix = format || 'txt'
      target_file = "#{target_file}.#{suffix}"
      job.content = File.read(target_file)
      File.unlink(target_file)
    end
  end
end
