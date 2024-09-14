# frozen_string_literal: true

require 'tempfile'

module Heathen
  # This is the instance of a conversion job itself. All the information needed by the
  # conversion tasks is held here.
  class Job
    # The action to be performed
    attr_accessor :action
    # The original document's language
    attr_accessor :language
    # The original document's mime_type
    attr_accessor :original_mime_type
    # The original document content
    attr_accessor :original_content
    # The current content (this may change, step-by-step)
    attr_reader :content
    # The current content's mime type
    attr_reader :mime_type
    # A scratch directory, where temporary files may be placed, in the knowledge
    # that they will be cleaned up when the job completes.
    attr_accessor :sandbox_dir

    # Constructs a new job
    # @param action [String] the action to be performed
    # @param content [String] the file body
    # @param language [String] the file's language
    # @param sandbox_dir [String] sandbox directory for temporary files
    def initialize(action, content, language = 'en', sandbox_dir = nil)
      @action = action
      @language = language
      @original_content = content
      @original_mime_type = content.mime_type
      self.content = @original_content
      @sandbox_dir = sandbox_dir
    end

    # Sets the current content to the supplied [String]. Will also
    # set mime_type and unlink the current temporary file (see [#content_file]).
    def content=(content)
      @content = content
      @mime_type = content.mime_type
      reset_content_file!
    end

    # Returns a path to the content stored on disk. This is needed by those conversion
    # steps which work only on files, rather than content in memory. The first time this
    # method is called, for a given step, a temporary file is created and the content is
    # written to it. This will persist until the content is changed.
    def content_file(suffix = '')
      return content_tempfile.path if content_tempfile

      @content_tempfile = Tempfile.new ["heathen", suffix], @sandbox_dir
      content_tempfile.binmode
      content_tempfile.write content
      content_tempfile.close

      content_tempfile.path
    end

    # Call this to reset the tempfile between multisteps tasks
    def reset_content_file!
      return if content_tempfile.nil?

      content_tempfile.unlink
      @content_tempfile = nil
    end

    private

    attr_reader :content_tempfile
  end
end
