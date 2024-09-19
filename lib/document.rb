# frozen_string_literal: true

require 'filemagic/ext'
require 'fileutils'
require 'json'
require 'pathname'
require 'stringio'

require_relative 'doc_key'

module Colore
  # This is a representation of the document stored on disk. Each doc is stored
  # in its own directory, which has this structure:
  #
  #     (doc_id) ┬─ metadata.json
  #              ├─ title
  #              ├─ current → v002
  #              ├─ v001 ─┬─ foo.docx
  #              │        └─ foo.pdf
  #              └─ v002 ─┬─ foo.docx
  #                       └─ foo.jpg
  #
  class Document
    attr_reader :base_dir
    attr_reader :doc_key

    CURRENT = 'current'
    AUTHOR_FILE = '_author.txt'

    # Returns document directory path
    # @param base_dir [String] The base path to the storage area
    # @param doc_key [DocKey] The document identifier
    # @return [Pathname]
    def self.directory(base_dir, doc_key)
      Pathname.new(base_dir) + doc_key.path
    end

    # Returns true if the document exists
    # @param base_dir [String] The base path to the storage area
    # @param doc_key [DocKey] The document identifier
    # @return [Bool]
    def self.exists?(base_dir, doc_key)
      File.exist? directory(base_dir, doc_key)
    end

    # Creates the document directory. Raises [DocumentExists] if the document already exists.
    # @param base_dir [String] The base path to the storage area
    # @param doc_key [DocKey] The document identifier
    # @return [Document]
    def self.create(base_dir, doc_key)
      doc_dir = directory base_dir, doc_key
      raise DocumentExists.new if File.exist? doc_dir

      FileUtils.mkdir_p doc_dir
      new base_dir, doc_key
    end

    # Loads the document information. Raises [DocumentNotFound] if the document does not exist.
    # @param base_dir [String] The base path to the storage area
    # @param doc_key [DocKey] The document identifier
    # @return [Document]
    def self.load(base_dir, doc_key)
      raise DocumentNotFound.new unless exists? base_dir, doc_key

      doc = new base_dir, doc_key
    end

    # Deletes the document directory (and all contents) if it exists.
    # @param base_dir [String] The base path to the storage area
    # @param doc_key [DocKey] The document identifier
    # @return [void].
    def self.delete(base_dir, doc_key)
      return unless exists? base_dir, doc_key

      FileUtils.rm_rf directory(base_dir, doc_key)
    end

    # Constructor.
    # @param base_dir [String] The base path to the storage area
    # @param doc_key [DocKey] The document identifier
    def initialize(base_dir, doc_key)
      @base_dir = base_dir
      @doc_key = doc_key
    end

    # @return the document storage directory.
    def directory
      self.class.directory @base_dir, @doc_key
    end

    # @return the document title.
    def title
      return '' unless File.exist?(directory + 'title')

      File.read(directory + 'title').chomp
    end

    # Sets the document title.
    def title=(new_title)
      return if new_title.to_s.empty?

      File.open(directory + 'title', 'w') { |f| f.puts new_title }
    end

    # Returns an array of the document version identifiers.
    def versions
      versions = Dir.glob(directory + 'v*')
      versions.map { |v| File.basename(v) }.grep(/\Av\d+\z/).sort
    end

    # Returns true if the document has the specified version.
    def has_version?(version)
      versions.include?(version) || version == CURRENT
    end

    # Returns the identifier of the current version.
    def current_version
      (directory + CURRENT).realpath.basename.to_s
    end

    # Returns the next version number (which would be created with [#new_version]).
    def next_version_number
      v_no = (versions.last || 'v000').delete('v').to_i + 1
      "v%03d" % [v_no]
    end

    # Creates a new version, ready to store documents in
    # Work is performed in a flock block to avoid concurrent race condition
    def new_version(&block)
      lockfile = directory + '.lock'
      nvn = nil
      lockfile.open 'w' do |f|
        f.flock File::LOCK_EX # lock is auto-released at end of block
        nvn = next_version_number
        Dir.mkdir directory + nvn
        yield nvn if block
      end
      nvn
    end

    # Adds the given file under the specified version.
    # @param version [String] the version identifier (can be 'current')
    # @param filename [String] the name of the file
    # @param body [String or IO] the file contents (binary string or IO)
    # @param author [String] the author of the file (optional)
    # @return [void]
    def add_file(version, filename, body, author = nil)
      raise VersionNotFound.new unless File.exist?(directory + version)

      body = StringIO.new(body) unless body.respond_to?(:read) # string -> IO
      File.open(directory + version + filename, "wb") { |f| IO.copy_stream(body, f) }
      File.write(directory + version + AUTHOR_FILE, author)
    end

    # Sets the specified version as current.
    def set_current(version)
      raise VersionNotFound.new unless File.exist?(directory + version)
      raise InvalidVersion.new unless /^v\d+$/.match?(version)

      # need to do this, or ln_s will put the symlink *into* the old dir
      File.unlink directory + CURRENT if File.exist? directory + CURRENT
      FileUtils.ln_s version, directory + CURRENT, force: true
    end

    # Deletes the given version, including its files.
    def delete_version(version)
      return unless File.exist?(directory + version)
      raise VersionIsCurrent.new if version == CURRENT
      raise VersionIsCurrent.new if (directory + CURRENT).realpath == (directory + version).realpath

      FileUtils.rm_rf(directory + version)
    end

    # Returns the URL query path for the given file. This can be used to construct a
    # full URL to the file, for example:
    #
    #   f = "http://colore:1234/#{doc.file_path 'v001', 'fred.docx'}"
    #
    def file_path(version, filename)
      # TODO: don't like this hard-code
      # it should really be in the app, but the hash is generated here
      "/document/#{@doc_key.app}/#{@doc_key.doc_id}/#{version}/#{filename}"
    end

    # Retrieves the requested file
    # @param version [String] the version identifier
    # @param filename [String] the name of the file
    # @return [String] mime type
    # @return [String] the file body
    def get_file(version, filename)
      path = directory + version + filename
      raise FileNotFound unless File.exist? path

      body = File.read path

      [body.mime_type, body]
    end

    # Summarises the document as a [Hash]
    def to_hash
      v_list = {}
      versions.each do |v|
        v_list[v] = {}
        Dir.glob(directory + v + '*').each do |file|
          pfile = Pathname.new(file)
          next if pfile.basename.to_s == AUTHOR_FILE

          content_type = File.read(pfile, [200, pfile.size].min).mime_type
          author = File.read(pfile.parent + AUTHOR_FILE).chomp rescue nil
          suffix = pfile.extname.delete('.')
          next if suffix.empty?

          v_list[v][suffix] = {
            content_type: content_type,
            filename: pfile.basename.to_s,
            path: file_path(v, pfile.basename),
            author: author,
            created_at: pfile.mtime,
          }
        end
      end
      {
        app: @doc_key.app,
        doc_id: @doc_key.doc_id,
        title: title,
        current_version: current_version,
        versions: v_list,
      }
    end

    # Saves the document metadata to (doc-dir)/metadata.json
    # This metadata is just the {#to_hash}, as JSON, and is intended for access by client
    # applications. It is not used by Colore for anything.
    def save_metadata
      File.open(directory + 'metadata.json', "w") do |f|
        f.puts JSON.pretty_generate(to_hash)
      end
    end
  end
end
