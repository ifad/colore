# frozen_string_literal: true

require 'haml'
require 'net/http'
require 'pathname'
require 'pp'
require 'sinatra/base'

require_relative 'colore'

module Colore
  # Sinatra API implementation for Colore (see config.ru). TODO: validate path-like parameters
  class App < Sinatra::Base
    set :backtrace, true
    before do
      @storage_dir = Pathname.new(C_.storage_directory)
      @legacy_url_base = C_.legacy_url_base || url('/')
      @logger = Logger.new(C_.conversion_log || STDOUT)
      @errlog = Logger.new(C_.error_log || STDERR)
    end

    # Landing page with API documentation
    get '/' do
      haml :index
    end

    # Custom 404 page
    not_found { JSON.dump(error: 'not found', status: 404, description: 'Document not found') }

    # Create document (will fail if document already exists)
    # POST params: title, actions, callback_url, file, author
    put '/document/:app/:doc_id/:filename' do |app, doc_id, filename|
      doc_key = DocKey.new app, doc_id
      doc = Document.create @storage_dir, doc_key # will raise if doc exists
      doc.title = params[:title] if params[:title]
      call env.merge('REQUEST_METHOD' => 'POST')
    rescue StandardError => e
      respond_with_error e
    end

    # Stores a new version. Side-effects: advances current version, performs conversions if actions specified
    # POST params: actions, callback_url, file, author
    post '/document/:app/:doc_id/:filename' do |app, doc_id, filename|
      doc_key = DocKey.new app, doc_id
      doc = Document.load(@storage_dir, doc_key)
      raise InvalidParameter.new :file unless params[:file]

      doc.new_version do |version|
        doc.add_file version, filename, params[:file][:tempfile], params[:author]
        doc.set_current version
        doc.save_metadata
      end
      (params[:actions] || []).each do |action|
        Sidekiq::ConversionWorker.perform_async(
          doc_key.to_s,
          doc.current_version,
          filename,
          action,
          params[:callback_url]
        )
      end
      respond 201, "Document stored", { app: app, doc_id: doc_id, path: doc.file_path(Colore::Document::CURRENT, filename) }
    rescue StandardError => e
      respond_with_error e
    end

    # Updates the document title
    post '/document/:app/:doc_id/title/:title' do |app, doc_id, title|
      doc_key = DocKey.new app, doc_id
      doc = Document.load(@storage_dir, doc_key)
      return reject_mock_operation if mock_document?(doc)

      doc.title = title
      doc.save_metadata
      respond 200, 'Title updated'
    rescue StandardError => e
      respond_with_error e
    end

    # Request new conversion (POST params: callback_url)
    post '/document/:app/:doc_id/:version/:filename/:action' do |app, doc_id, version, filename, action|
      doc_key = DocKey.new app, doc_id
      doc = Document.load @storage_dir, doc_key
      return respond 202, "Mock conversion accepted" if mock_document?(doc)

      raise VersionNotFound.new unless doc.has_version? version

      Sidekiq::ConversionWorker.perform_async doc_key, version, filename, action, params[:callback_url]
      respond 202, "Conversion initiated"
    rescue StandardError => e
      respond_with_error e
    end

    # Delete document
    delete '/document/:app/:doc_id' do |app, doc_id|
      Document.delete @storage_dir, DocKey.new(app, doc_id)
      respond 200, 'Document deleted'
    rescue StandardError => e
      respond_with_error e
    end

    # Delete document version
    delete '/document/:app/:doc_id/:version' do |app, doc_id, version|
      doc = Document.load @storage_dir, DocKey.new(app, doc_id)
      doc.delete_version version
      doc.save_metadata
      respond 200, 'Document version deleted'
    rescue StandardError => e
      respond_with_error e
    end

    # Get file (disabled in production)
    get '/document/:app/:doc_id/:version/:filename' do |app, doc_id, version, filename|
      doc = Document.load @storage_dir, DocKey.new(app, doc_id)
      ctype, file = doc.get_file(version, filename)
      content_type ctype
      file
    rescue StandardError => e
      respond_with_error e
    end unless environment == :production

    # Get document info
    get '/document/:app/:doc_id' do |app, doc_id|
      doc = Document.load @storage_dir, DocKey.new(app, doc_id)
      respond 200, 'Information retrieved', doc.to_hash
    rescue StandardError => e
      respond_with_error e
    end

    # Convert document (POST params: file, action, language)
    post '/convert' do
      unless params[:file]
        return respond 400, "missing file parameter"
      end

      unless params[:file].respond_to?(:fetch) and params[:file].fetch(:tempfile, nil).respond_to?(:read)
        return respond 400, "invalid file parameter"
      end

      body = params[:file][:tempfile].read
      content = Converter.new(logger: @logger).convert_file(params[:action], body, params[:language])
      content_type content.mime_type
      content
    rescue StandardError => e
      respond_with_error e
    end

    # Legacy method to convert files (POST params: file, url, action)
    post "/#{LegacyConverter::LEGACY}/convert" do
      body = if params[:file]
               params[:file][:tempfile].read
             elsif params[:url]
               Net::HTTP.get URI(params[:url])
             else
               return respond 400, "Please specify either 'file' or 'url' POST variable"
             end
      path = LegacyConverter.new.convert_file params[:action], body, params[:language]
      converted_url = @legacy_url_base + path
      content_type 'application/json'
      { original: '', converted: converted_url }.to_json
    rescue StandardError => e
      legacy_error e, e.message
    end

    # Legacy method to retrieve converted file (for development if Nginx not used)
    get "/#{LegacyConverter::LEGACY}/:file_id" do |file_id|
      content = LegacyConverter.new.get_file file_id
      content_type content.mime_type
      content
    rescue StandardError => e
      legacy_error 400, e.message
    end

    # rubocop:disable Metrics/BlockLength
    helpers do
      # Renders all responses (including errors) in a standard JSON format.
      def respond(status, message, extra = {})
        case status
        when Colore::Error
          status = status.http_code
        when StandardError
          extra[:backtrace] = status.backtrace if params[:backtrace]
          status = 500
        end
        content_type 'application/json'

        [
          status,
          { status: status, description: message }.merge(extra).to_json,
        ]
      end

      def respond_with_error(error)
        log = +''
        log << "While processing #{request.request_method} #{request.path} with params:\n"
        log << request.params.pretty_inspect
        log << "\nthe following error occurred: #{error.class} #{error.message}"
        log << "\nbacktrace:"
        log << "  " << error.backtrace.join("\n  ")

        @errlog.error(log)

        respond error, error.message
      end

      # Renders all responses (including errors) in a standard JSON format.
      def legacy_error(status, message, extra = {})
        case status
        when Error
          status = status.http_code
        when StandardError
          extra[:backtrace] = status.backtrace if params[:backtrace]
          status = 500
        end
        content_type 'application/json'

        [
          status,
          { error: message }.merge(extra).to_json,
        ]
      end

      # Check if document is a mock
      def mock_document?(doc)
        doc.is_a?(Colore::MockDocument)
      end

      # Standard response for mock document operations
      def reject_mock_operation
        respond 400, 'Operation not supported on mock documents'
      end
    end
    # rubocop:enable Metrics/BlockLength
  end
end
