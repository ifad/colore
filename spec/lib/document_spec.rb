# frozen_string_literal: true

require 'spec_helper'
require 'colore'

RSpec.describe Colore::Document do
  let(:app) { 'app' }
  let(:doc_id) { '12345' }
  let(:doc_key) { Colore::DocKey.new(app, doc_id) }
  let(:invalid_doc_key) { Colore::DocKey.new(app, 'bollox') }
  let(:storage_dir) { tmp_storage_dir }
  let(:document) { described_class.load storage_dir, doc_key }
  let(:author) { 'spliffy' }

  before do
    setup_storage
  end

  after do
    delete_storage
  end

  describe '.directory' do
    it 'runs' do
      expect(described_class.directory(storage_dir, doc_key).to_s).not_to be_nil
    end
  end

  describe '.exists?' do
    it 'runs' do
      expect(described_class.exists?(storage_dir, doc_key)).to be true
    end

    it 'returns false if directory does not exist' do
      expect(described_class.exists?(storage_dir, invalid_doc_key)).to be false
    end
  end

  describe '.create' do
    it 'runs' do
      create_key = Colore::DocKey.new('app2', 'foo')
      doc = described_class.create storage_dir, create_key
      expect(doc).not_to be_nil
      expect(described_class.exists?(storage_dir, create_key)).to be true
    end

    it 'raises error if doc already exists' do
      expect do
        described_class.create storage_dir, doc_key
      end.to raise_error Colore::DocumentExists
    end
  end

  describe '.load' do
    it 'runs' do
      doc = described_class.load storage_dir, doc_key
      expect(doc).not_to be_nil
    end

    it 'raises exception if directory does not exist' do
      expect do
        described_class.load storage_dir, invalid_doc_key
      end.to raise_error Colore::DocumentNotFound
    end
  end

  describe '.delete' do
    it 'runs' do
      described_class.delete storage_dir, doc_key
      expect(described_class.exists?(storage_dir, doc_key)).to be false
    end
  end

  describe '#directory' do
    it 'runs' do
      expect(document.directory).to exist
    end
  end

  describe '#title' do
    it 'runs' do
      expect(document.title).to eq 'Sample document'
    end
  end

  describe '#title=' do
    it 'runs' do
      document.title = 'New title'
      new_doc = described_class.load storage_dir, doc_key
      expect(new_doc.title).to eq 'New title'
    end

    it 'does not save a nil title' do
      document.title = nil
      new_doc = described_class.load storage_dir, doc_key
      expect(new_doc.title).to eq 'Sample document'
    end
  end

  describe '#versions' do
    it 'runs' do
      expect(document.versions).to contain_exactly('v001', 'v002')
    end
  end

  describe '#has_version?' do
    it 'runs' do
      expect(document.has_version?('v001')).to be true
    end

    it 'accepts current' do
      expect(document.has_version?('current')).to be true
    end

    it 'rejects invalid' do
      expect(document.has_version?('foo')).to be false
    end
  end

  describe '#current_version' do
    it 'runs' do
      expect(document.current_version).to eq 'v002'
    end
  end

  describe '#next_version_number' do
    it 'runs' do
      expect(document.next_version_number).to eq 'v003'
    end
  end

  describe '#new_version' do
    it 'runs' do
      version = document.new_version
      expect(version).not_to be_nil
      expect(document.directory.join(version)).to exist
      new_doc = described_class.load storage_dir, doc_key
      expect(new_doc.versions.include?(version)).to be true
    end
  end

  describe '#add_file' do
    let(:file) { fixture('heathen/test.txt') }

    it 'runs without author' do
      document.add_file 'v002', File.basename(file), file.read
      expect(document.directory.join('v002', File.basename(file))).to exist
      expect(document.directory.join('v002', described_class::AUTHOR_FILE).read.chomp).to eq ''
    end

    it 'runs with author' do
      document.add_file 'v002', File.basename(file), file.read, author
      expect(document.directory.join('v002', File.basename(file))).to exist
      expect(document.directory.join('v002', described_class::AUTHOR_FILE).read.chomp).to eq author
    end

    it 'runs with IO for body' do
      document.add_file 'v002', File.basename(file), file.read
      expect(document.directory.join('v002', File.basename(file))).to exist
    end
  end

  describe '#set_current' do
    it 'runs' do
      document.set_current 'v001'
      st1 = document.directory.join('current').stat
      st2 = document.directory.join('v001').stat
      expect(st1.ino).to eq st2.ino
    end

    it 'fails with a non-existing version' do
      expect do
        document.set_current 'v009'
      end.to raise_error Colore::VersionNotFound
    end

    it 'fails with an invalid version name' do
      expect do
        document.set_current 'title'
      end.to raise_error Colore::InvalidVersion
    end
  end

  describe '#delete_version' do
    it 'runs' do
      document.delete_version 'v001'
      expect(document.directory.join('v001')).not_to exist
    end

    it 'refuses to delete "current"' do
      expect do
        document.delete_version Colore::Document::CURRENT
      end.to raise_error Colore::VersionIsCurrent
    end

    it 'refuses to delete current version' do
      expect do
        document.delete_version 'v002'
      end.to raise_error Colore::VersionIsCurrent
    end

    it 'silently does nothing for an invalid version' do
      expect(document.delete_version('foo')).to be_nil
    end
  end

  describe '#file_path' do
    it 'runs' do
      expect(document.file_path('v001', 'arglebargle.docx')).to eq "/document/#{app}/#{doc_id}/v001/arglebargle.docx"
    end
  end

  describe '#get_file' do
    it 'runs' do
      content_type, body = document.get_file 'v001', 'arglebargle.docx'
      expect(content_type).to eq 'application/vnd.openxmlformats-officedocument.wordprocessingml.document; charset=binary'
      expect(body).not_to be_nil
    end

    it 'runs for current' do
      content_type, body = document.get_file Colore::Document::CURRENT, 'arglebargle.txt'
      expect(content_type).to eq 'text/plain; charset=us-ascii'
      expect(body).not_to be_nil
    end

    it 'raises FileNotFound for an invalid version' do
      expect do
        document.get_file 'foo', 'arglebargle.txt'
      end.to raise_error Colore::FileNotFound
    end

    it 'raises FileNotFound for an invalid filename' do
      expect do
        document.get_file 'v001', 'text/plain; charset=us-ascii'
      end.to raise_error Colore::FileNotFound
    end
  end

  describe '#to_hash' do
    it 'runs' do
      testhash = JSON.parse(fixture('document.json').read)
      testhash = Colore::Utils.symbolize_keys testhash
      dochash = Colore::Utils.symbolize_keys document.to_hash
      dochash[:versions].each_value do |v|
        v.each_value { |v1| v1.delete :created_at }
      end
      expect(dochash).to match testhash
    end

    context 'when file size is zero' do
      let(:doc_id) { '12346' }

      it 'reports the correct mime type' do
        dochash = Colore::Utils.symbolize_keys document.to_hash
        content_type = dochash[:versions][:v001][:docx][:content_type]

        expect(content_type).to eq 'application/x-empty; charset=binary'
      end
    end
  end

  describe '#save_metadata' do
    it 'runs' do
      document.save_metadata
      expect(document.directory.join('metadata.json')).to exist

      expect do
        JSON.parse document.directory.join('metadata.json').read
      end.not_to raise_error
    end
  end
end
