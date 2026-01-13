# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Colore::MockDocument do
  let(:doc_key) { Colore::DocKey.new 'test-app', 'doc-123' }
  let(:mock_doc) { described_class.new doc_key }

  describe '#title' do
    it 'returns a mock title with document ID' do
      expect(mock_doc.title).to eq 'Mock Document - doc-123'
    end
  end

  describe '#versions' do
    it 'returns array with v001' do
      expect(mock_doc.versions).to eq ['v001']
    end
  end

  describe '#current_version' do
    it 'returns v001 as current version' do
      expect(mock_doc.current_version).to eq 'v001'
    end
  end

  describe '#has_version?' do
    it 'returns true for v001' do
      expect(mock_doc.has_version?('v001')).to be true
    end

    it 'returns true for current' do
      expect(mock_doc.has_version?('current')).to be true
    end

    it 'returns false for other versions' do
      expect(mock_doc.has_version?('v002')).to be false
    end
  end

  describe '#get_file' do
    context 'when requesting a text file' do
      it 'returns text/plain content' do
        ctype, content = mock_doc.get_file('v001', 'document.txt')
        expect(ctype).to include 'text/plain'
        expect(content).to include 'This is a mock document'
      end
    end

    context 'when requesting a PDF file' do
      it 'returns application/pdf content' do
        ctype, content = mock_doc.get_file('v001', 'document.pdf')
        expect(ctype).to include 'application/pdf'
        expect(content).to include '%PDF-1.4'
      end
    end

    context 'when requesting an HTML file' do
      it 'returns text/html content' do
        ctype, content = mock_doc.get_file('v001', 'document.html')
        expect(ctype).to include 'text/html'
        expect(content).to include '<h1>Mock Document</h1>'
      end
    end

    context 'when requesting a JSON file' do
      it 'returns application/json content' do
        ctype, content = mock_doc.get_file('v001', 'document.json')
        expect(ctype).to include 'application/json'
        expect(content).to include 'doc_id'
      end
    end

    context 'when requesting an unknown file type' do
      it 'returns text/plain as default' do
        ctype, content = mock_doc.get_file('v001', 'document.xyz')
        expect(ctype).to include 'text/plain'
        expect(content).to include 'Mock document file: document.xyz'
      end
    end
  end

  describe '#file_path' do
    it 'returns correct URL path' do
      path = mock_doc.file_path('v001', 'document.txt')
      expect(path).to eq '/document/test-app/doc-123/v001/document.txt'
    end
  end

  describe '#to_hash' do
    let(:hash) { mock_doc.to_hash }

    it 'returns hash with document metadata' do
      expect(hash).to be_a Hash
      expect(hash[:app]).to eq 'test-app'
      expect(hash[:doc_id]).to eq 'doc-123'
      expect(hash[:title]).to eq 'Mock Document - doc-123'
    end

    it 'includes version information' do
      expect(hash[:versions]).to have_key :v001
    end

    it 'includes file entries' do
      v001 = hash[:versions][:v001]
      expect(v001).to include :txt
      expect(v001).to include :pdf
    end

    it 'includes file metadata' do
      txt_file = hash[:versions][:v001][:txt]
      expect(txt_file[:content_type]).to include 'text/plain'
      expect(txt_file[:filename]).to eq 'document.txt'
      expect(txt_file[:author]).not_to be_nil
    end
  end
end
