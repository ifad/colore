# frozen_string_literal: true

module Heathen
  class Processor
    def detect_language
      executioner.execute(
        Colore::C_.tika_path,
        "--config=#{Colore::TikaConfig.path_for_language_detection}",
        '--language',
        job.content_file,
        binary: true
      )
      raise ConversionFailed.new if executioner.last_exit_status != 0

      job.content = executioner.stdout
    end
  end
end
