# frozen_string_literal: true

module Heathen
  class Processor
    def pdftotext
      expect_mime_type 'application/pdf'

      executioner.execute(
        Colore::C_.tika_path,
        "--config=#{Colore::TikaConfig.path_for(job.language)}",
        '--text',
        job.content_file,
        binary: true
      )
      raise ConversionFailed.new(executioner.last_messages) if executioner.last_exit_status != 0

      job.content = executioner.stdout
    end
  end
end
