require 'logger'

module Heathen
  # The Converter takes the given action and input content, identifies the task required
  # to perform the action, then constructs a [Processor] to convert the document.
  class Converter
    def initialize( logger: Logger.new(nil) )
      @logger = logger
    end

    # Converts the given document according to the action requested.
    # @param action [String] the conversion action to perform
    # @param content [String] the document body to be converted
    # @param language [String] the document language (defaults to 'en')
    # @return [String] the converted document body
    def convert action, content, language='en'
      job = Job.new action, content, language
      processor = Heathen::Processor.new job: job, logger: @logger
      begin
        processor.perform_task action
      ensure
        processor.clean_up
      end
      job.content
    end
  end
end
