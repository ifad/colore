# frozen_string_literal: true

module Heathen
  class Processor
    def mdtopdf
      expect_mime_type 'text/markdown'

      executioner.execute(
        Colore::C_.pandoc_path,
        '-f markdown -t pdf',
        job.content_file,
        binary: true
      )
      raise ConversionFailed.new(executioner.last_messages) if executioner.last_exit_status != 0

      job.content = executioner.stdout
    end
  end
end
