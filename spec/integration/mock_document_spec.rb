# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Mock Document Integration' do
  include Rack::Test::Methods

  def app
    Colore::App
  end

  let(:mock_storage_dir) { Pathname.new('spec/fixtures/app') }
  let(:original_mock_setting) { Colore::C_.mock_documents_enabled }
  let(:test_doc_key) { Colore::DocKey.new 'test-app', 'mock-123' }

  before do
    # Enable mock documents for testing
    original_mock_setting # Initialize the let variable
    Colore::C_.mock_documents_enabled = true

    # Ensure the test document doesn't exist
    Colore::Document.delete mock_storage_dir, test_doc_key
  end

  after do
    # Restore original setting
    Colore::C_.mock_documents_enabled = original_mock_setting
  end

  describe 'GET /document/:app/:doc_id' do
    it 'returns mock document info when document does not exist' do
      get '/document/test-app/mock-123'

      expect(last_response.status).to eq 200
      data = JSON.parse last_response.body
      expect(data['app']).to eq 'test-app'
      expect(data['doc_id']).to eq 'mock-123'
      expect(data['title']).to include 'Mock Document'
    end

    it 'returns actual document when it exists' do
      # Use an existing document from fixtures
      get '/document/a3/12346'

      expect(last_response.status).to eq 200
      data = JSON.parse last_response.body
      expect(data['app']).to eq 'a3'
      expect(data['doc_id']).to eq '12346'
    end
  end

  describe 'GET /document/:app/:doc_id/:version/:filename' do
    context 'when mock documents are enabled' do
      it 'returns mock file content for non-existent document' do
        get '/document/test-app/mock-456/v001/document.txt'

        expect(last_response.status).to eq 200
        expect(last_response.content_type).to include 'text/plain'
        expect(last_response.body).to include 'This is a mock document'
      end

      it 'returns PDF content for PDF requests' do
        get '/document/test-app/mock-456/v001/document.pdf'

        expect(last_response.status).to eq 200
        expect(last_response.content_type).to include 'application/pdf'
        expect(last_response.body).to include '%PDF'
      end
    end
  end

  describe 'POST /document/:app/:doc_id/title/:title' do
    it 'returns 400 error when trying to update mock document title' do
      post '/document/test-app/mock-789/title/New%20Title'

      expect(last_response.status).to eq 400
      data = JSON.parse last_response.body
      expect(data['description']).to include 'mock document'
    end
  end

  describe 'POST /document/:app/:doc_id/:version/:filename/:action' do
    it 'returns 202 without processing conversion for mock document' do
      post '/document/test-app/mock-789/v001/document.txt/htmltotext'

      expect(last_response.status).to eq 202
      data = JSON.parse last_response.body
      expect(data['description']).to include 'Mock conversion request'
    end
  end

  describe 'when mock documents are disabled' do
    before do
      Colore::C_.mock_documents_enabled = false
    end

    it 'raises DocumentNotFound when document does not exist' do
      get '/document/test-app/not-found-789'

      expect(last_response.status).to eq 404
      data = JSON.parse last_response.body
      expect(data['error']).to include 'not found'
    end
  end
end
