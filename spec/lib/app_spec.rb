# frozen_string_literal: true

require 'spec_helper'
require 'app'

RSpec.describe Colore::App do
  include Rack::Test::Methods

  subject(:app) { described_class }

  let(:appname) { 'app' }
  let(:doc_id) { '12345' }
  let(:filename) { 'arglebargle.docx' }
  let(:doc_key) { Colore::DocKey.new(app, doc_id) }
  let(:new_doc_id) { '54321' }
  let(:invalid_doc_id) { 'foobar' }
  let(:storage_dir) { tmp_storage_dir }
  let(:author) { 'spliffy' }

  def show_backtrace(response)
    return unless response.status == 500

    begin
      puts JSON.pretty_generate(JSON.parse(response.body))
    rescue StandardError
      puts response.body
    end
  end

  before do
    setup_storage
    allow(Colore::C_.config).to receive(:storage_directory).and_return(tmp_storage_dir)
    allow(Colore::Sidekiq::ConversionWorker).to receive(:perform_async)
  end

  after do
    delete_storage
  end

  describe 'GET home' do
    it 'gets the home page' do
      get '/'

      expect(last_response.status).to eq 200
    end
  end

  describe 'PUT create document' do
    it 'creates a new document' do
      put "/document/#{appname}/#{new_doc_id}/#{filename}", {
        title: 'A title',
        file: Rack::Test::UploadedFile.new(__FILE__, 'application/ruby'),
        actions: %w[ocr pdf],
        author: author,
        backtrace: true,
      }
      show_backtrace last_response
      expect(last_response.status).to eq 201
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to match(
        { "status" => 201, "description" => "Document stored", "app" => "app", "doc_id" => "54321", "path" => "/document/app/54321/current/arglebargle.docx" }
      )
      expect(Colore::Sidekiq::ConversionWorker).to have_received(:perform_async).twice
    end

    it 'fails to create an existing document' do
      put "/document/#{appname}/#{doc_id}/#{filename}", {
        title: 'A title',
        file: Rack::Test::UploadedFile.new(__FILE__, 'application/ruby'),
        actions: %w[ocr pdf],
        backtrace: true,
      }
      show_backtrace last_response
      expect(last_response.status).to eq 409
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to be_a Hash
      expect(Colore::Sidekiq::ConversionWorker).not_to have_received(:perform_async)
    end
  end

  describe 'POST update document' do
    it 'runs' do
      post "/document/#{appname}/#{doc_id}/#{filename}", {
        file: Rack::Test::UploadedFile.new(__FILE__, 'application/ruby'),
        actions: %w[ocr pdf],
        backtrace: true,
      }
      show_backtrace last_response
      expect(last_response.status).to eq 201
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to match(
        { "status" => 201, "description" => "Document stored", "app" => "app", "doc_id" => "12345", "path" => "/document/app/12345/current/arglebargle.docx" }
      )
      expect(Colore::Sidekiq::ConversionWorker).to have_received(:perform_async).twice
    end

    it 'fails if document does not exist' do
      post "/document/#{appname}/#{new_doc_id}/#{filename}", {
        file: Rack::Test::UploadedFile.new(__FILE__, 'application/ruby'),
        actions: %w[ocr pdf],
        author: author,
        backtrace: true,
      }
      expect(last_response.status).to eq 404
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to be_a Hash
      expect(Colore::Sidekiq::ConversionWorker).not_to have_received(:perform_async)
    end
  end

  describe 'POST update title' do
    it 'runs' do
      title = "This is a new document"
      post "/document/#{appname}/#{doc_id}/title/#{URI.encode_www_form_component(title)}"
      expect(last_response.status).to eq 200
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to be_a Hash
    end

    it 'fails if the document does not exist' do
      title = "This is a new document"
      post "/document/#{appname}/foobar/title/#{URI.encode_www_form_component(title)}"
      expect(last_response.status).to eq 404
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to be_a Hash
    end
  end

  describe 'POST new conversion' do
    it 'starts a new conversion' do
      post "/document/#{appname}/#{doc_id}/current/#{filename}/ocr", {
        backtrace: true,
      }
      show_backtrace last_response
      expect(last_response.status).to eq 202
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to match(
        { "status" => 202, "description" => "Conversion initiated" }
      )
      expect(Colore::Sidekiq::ConversionWorker).to have_received(:perform_async).once
    end

    it 'fails if invalid document' do
      post "/document/#{appname}/#{invalid_doc_id}/current/#{filename}/ocr", {
        backtrace: true,
      }
      show_backtrace last_response
      expect(last_response.status).to eq 404
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to be_a Hash
      expect(Colore::Sidekiq::ConversionWorker).not_to have_received(:perform_async)
    end

    it 'fails if invalid version' do
      post "/document/#{appname}/#{doc_id}/fred/#{filename}/ocr", {
        backtrace: true,
      }
      show_backtrace last_response
      expect(last_response.status).to eq 400
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to be_a Hash
      expect(Colore::Sidekiq::ConversionWorker).not_to have_received(:perform_async)
    end
  end

  describe 'DELETE document' do
    it 'runs' do
      delete "/document/#{appname}/#{doc_id}", {
        deleted_by: 'a.person',
      }
      show_backtrace last_response
      expect(last_response.status).to eq 200
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to match(
        { "status" => 200, "description" => "Document deleted" }
      )
    end
  end

  describe 'DELETE document version' do
    it 'runs' do
      delete "/document/#{appname}/#{doc_id}/v001", {
        deleted_by: 'a.person',
      }
      show_backtrace last_response
      expect(last_response.status).to eq 200
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to match(
        { "status" => 200, "description" => "Document version deleted" }
      )
    end

    it 'fails if you try to delete current' do
      delete "/document/#{appname}/#{doc_id}/current", {
        deleted_by: 'a.person',
      }
      show_backtrace last_response
      expect(last_response.status).to eq 400
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to be_a Hash
    end

    it 'fails if you try to delete the current version' do
      delete "/document/#{appname}/#{doc_id}/v002", {
        deleted_by: 'a.person',
      }
      show_backtrace last_response
      expect(last_response.status).to eq 400
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to be_a Hash
    end
  end

  describe 'GET document' do
    it 'runs' do
      get "/document/#{appname}/#{doc_id}/current/#{filename}?backtrace=true"
      show_backtrace last_response
      expect(last_response.status).to eq 200
      expect(last_response.content_type).to eq 'application/vnd.openxmlformats-officedocument.wordprocessingml.document; charset=binary'
      expect(last_response.body).not_to be_nil
    end

    it 'fails for an invalid document' do
      get "/document/#{appname}/#{invalid_doc_id}/current/#{filename}"
      expect(last_response.status).to eq 404
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to be_a Hash
    end

    it 'fails for an invalid filename' do
      get "/document/#{appname}/#{doc_id}/current/foo.txt"
      expect(last_response.status).to eq 400
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to be_a Hash
    end
  end

  describe 'GET document info' do
    it 'runs' do
      get "/document/#{appname}/#{doc_id}?backtrace=true"
      show_backtrace last_response
      expect(last_response.status).to eq 200
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to be_a Hash
    end

    it 'fails for an invalid document' do
      get "/document/#{appname}/#{invalid_doc_id}"
      expect(last_response.status).to eq 404
      expect(last_response.content_type).to eq 'application/json'
      expect(JSON.parse(last_response.body)).to be_a Hash
    end
  end

  describe 'POST /convert' do
    context 'when file is nil' do
      it 'returns an error' do
        params = {
          file: nil,
        }
        post "/convert", params
        expect(last_response.status).to eq 400
        body = JSON.parse(last_response.body)
        expect(body).to be_a Hash
        expect(body['description']).to eq "missing file parameter"
      end
    end

    context 'when file is not correct' do
      it 'returns an error' do
        params = {
          file: "I'm definitely not a file",
        }
        post "/convert", params
        expect(last_response.status).to eq 400
        body = JSON.parse(last_response.body)
        expect(body).to be_a Hash
        expect(body['description']).to eq "invalid file parameter"
      end
    end

    it 'converts and saves file' do
      stubbed_converter = instance_double(Colore::Converter)
      allow(Colore::Converter).to receive(:new).and_return(stubbed_converter)
      params = {
        action: 'pdf',
        file: Rack::Test::UploadedFile.new(__FILE__, 'application/ruby'),
      }
      allow(stubbed_converter).to receive(:convert_file).with(params[:action], String, nil).and_return("%PDF-1.4")
      post "/convert", params
      expect(last_response.status).to eq 200
      expect(last_response.content_type).to eq 'application/pdf; charset=us-ascii'
      expect(last_response.body).to eq '%PDF-1.4'
    end

    it 'returns correct JSON structure on fail' do
      stubbed_converter = instance_double(Colore::Converter)
      allow(Colore::Converter).to receive(:new).and_return(stubbed_converter)
      params = {
        action: 'pdf',
        file: Rack::Test::UploadedFile.new(__FILE__, 'application/ruby'),
      }
      allow(stubbed_converter).to receive(:convert_file).and_raise 'Argh'
      post "/convert", params
      expect(last_response.status).to eq 500
      expect(last_response.content_type).to eq 'application/json'
      body = JSON.parse(last_response.body)
      expect(body).to be_a Hash
      expect(body['description']).to eq 'Argh'
    end
  end

  describe 'POST /legacy/convert' do
    it 'converts and saves file' do
      stubbed_converter = instance_double(Colore::LegacyConverter)
      allow(Colore::LegacyConverter).to receive(:new).and_return(stubbed_converter)
      params = {
        action: 'pdf',
        file: Rack::Test::UploadedFile.new(__FILE__, 'application/ruby'),
      }
      expect(stubbed_converter).to receive(:convert_file).with(params[:action], String, nil).and_return('foobar')
      post "/#{Colore::LegacyConverter::LEGACY}/convert", params
      expect(last_response.status).to eq 200
      expect(last_response.content_type).to eq 'application/json'
      body = JSON.parse(last_response.body)
      expect(body).to be_a Hash
      expect(body['converted']).not_to eq ''
    end

    it 'converts and saves URL' do
      stubbed_converter = instance_double(Colore::LegacyConverter)
      allow(Colore::LegacyConverter).to receive(:new).and_return(stubbed_converter)
      params = {
        action: 'pdf',
        url: 'http://localhost/foo/bar',
      }
      expect(Net::HTTP).to receive(:get).with(URI(params[:url])).and_return('The quick brown flox')
      expect(stubbed_converter).to receive(:convert_file).with(params[:action], String, nil).and_return('foobar')
      post "/#{Colore::LegacyConverter::LEGACY}/convert", params
      expect(last_response.status).to eq 200
      expect(last_response.content_type).to eq 'application/json'
      body = JSON.parse(last_response.body)
      expect(body).to be_a Hash
      expect(body['converted']).not_to eq ''
    end

    it 'returns correct JSON structure on fail' do
      stubbed_converter = instance_double(Colore::LegacyConverter)
      allow(Colore::LegacyConverter).to receive(:new).and_return(stubbed_converter)
      params = {
        action: 'pdf',
        file: Rack::Test::UploadedFile.new(__FILE__, 'application/ruby'),
      }
      allow(stubbed_converter).to receive(:convert_file).and_raise 'Argh'
      post "/#{Colore::LegacyConverter::LEGACY}/convert", params
      expect(last_response.status).to eq 500
      expect(last_response.content_type).to eq 'application/json'
      body = JSON.parse(last_response.body)
      expect(body).to be_a Hash
      expect(body['error']).to eq 'Argh'
    end

    context 'without parameters' do
      it 'returns an error' do
        post "/#{Colore::LegacyConverter::LEGACY}/convert"
        expect(last_response.status).to eq 400
        expect(last_response.content_type).to eq 'application/json'
        body = JSON.parse(last_response.body)
        expect(body).to be_a Hash
        expect(body['description']).to eq "Please specify either 'file' or 'url' POST variable"
      end
    end
  end

  describe 'GET /legacy/:file_id' do
    it 'runs' do
      Colore::LegacyConverter.new.store_file 'foo.txt', 'The quick brown fox'
      get "/#{Colore::LegacyConverter::LEGACY}/foo.txt"
      expect(last_response.status).to eq 200
      expect(last_response.content_type).to eq 'text/plain; charset=us-ascii'
      expect(last_response.body).to eq 'The quick brown fox'
    end

    it 'returns correct JSON structure on fail' do
      get "/#{Colore::LegacyConverter::LEGACY}/foo.txt"
      expect(last_response.status).to eq 400
      expect(last_response.content_type).to eq 'application/json'
      body = JSON.parse(last_response.body)
      expect(body).to be_a Hash
      expect(body['error']).to eq 'File does not exist'
    end
  end
end
