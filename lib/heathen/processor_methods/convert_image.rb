module Heathen
  class Processor
    # Converts an image to a different image format. This is done by running the 'convert'
    # utility from ImageMagick. Sets the job content to the new format.
    # @param to [String] the format to convert to (suffix)
    # @param params [Array] optional parameters to pass to the convert program.
    def convert_image(to: 'tiff', params: '')
      expect_mime_type 'image/*'

      target_file = temp_file_name '', ".#{to}"
      executioner.execute(
        *[
          Colore::C_.convert_path,
          job.content_file,
          params.split(/ +/),
          target_file,
        ].flatten
      )
      raise ConversionFailed.new if executioner.last_exit_status != 0

      c = File.read(target_file)
      job.content = File.read(target_file)
      File.unlink(target_file)
    end
  end
end
