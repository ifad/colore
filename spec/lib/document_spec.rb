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
      expect(described_class.exists?(storage_dir, doc_key)).to eq true
    end

    it 'returns false if directory does not exist' do
      expect(described_class.exists?(storage_dir, invalid_doc_key)).to eq false
    end
  end

  describe '.create' do
    it 'runs' do
      create_key = Colore::DocKey.new('app2', 'foo')
      doc = described_class.create storage_dir, create_key
      expect(doc).not_to be_nil
      expect(described_class.exists?(storage_dir, create_key)).to eq true
    end

    it 'raises error if doc already exists' do
      expect {
        described_class.create storage_dir, doc_key
      }.to raise_error Colore::DocumentExists
    end
  end

  describe '.load' do
    it 'runs' do
      doc = described_class.load storage_dir, doc_key
      expect(doc).not_to be_nil
    end

    it 'raises exception if directory does not exist' do
      expect {
        described_class.load storage_dir, invalid_doc_key
      }.to raise_error Colore::DocumentNotFound
    end
  end

  describe '.delete' do
    it 'runs' do
      Colore::Document.delete storage_dir, doc_key
      expect(Colore::Document.exists?(storage_dir, doc_key)).to eq false
    end
  end

  describe '#directory' do
    it 'runs' do
      dir = document.directory
      expect(dir).not_to be_nil
      expect(File.exist?(dir)).to eq true
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
      expect(document.has_version?('v001')).to eq true
    end

    it 'accepts current' do
      expect(document.has_version?('current')).to eq true
    end

    it 'rejects invalid' do
      expect(document.has_version?('foo')).to eq false
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
      expect(File.exist?(document.directory + version)).to eq true
      new_doc = described_class.load storage_dir, doc_key
      expect(new_doc.versions.include?(version)).to eq true
    end
  end

  describe '#add_file' do
    it 'runs without author' do
      file = __FILE__
      body = File.read(file)
      document.add_file 'v002', File.basename(file), body
      expect(File.exist?(document.directory + 'v002' + File.basename(file))).to eq true
    end

    it 'runs with author' do
      file = __FILE__
      body = File.read(file)
      document.add_file 'v002', File.basename(file), body, author
      expect(File.exist?(document.directory + 'v002' + File.basename(file))).to eq true
      expect(File.exist?(document.directory + 'v002' + described_class::AUTHOR_FILE)).to eq true
      expect(File.read(document.directory + 'v002' + described_class::AUTHOR_FILE).chomp).to eq author
    end

    it 'runs with IO for body' do
      file = __FILE__
      body = File.open(file)
      document.add_file 'v002', File.basename(file), body
      expect(File.exist?(document.directory + 'v002' + File.basename(file))).to eq true
    end
  end

  describe '#set_current' do
    it 'runs' do
      document.set_current 'v001'
      st1 = File.stat(document.directory + 'current')
      st2 = File.stat(document.directory + 'v001')
      expect(st1.ino).to eq st2.ino
    end

    it 'fails when you try an invalid version' do
      expect {
        document.set_current 'v009'
      }.to raise_error Colore::VersionNotFound
    end

    it 'fails when you try an invalid version name' do
      expect {
        document.set_current 'title'
      }.to raise_error Colore::InvalidVersion
    end
  end

  describe '#delete_version' do
    it 'runs' do
      document.delete_version 'v001'
      expect(File.exist?(document.directory + 'v001')).to eq false
    end

    it 'refuses to delete "current"' do
      expect {
        document.delete_version Colore::Document::CURRENT
      }.to raise_error Colore::VersionIsCurrent
    end

    it 'refuses to delete current version' do
      expect {
        document.delete_version 'v002'
      }.to raise_error Colore::VersionIsCurrent
    end

    it 'silently does nothing for an invalid version' do
      document.delete_version 'foo'
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
      expect {
        document.get_file 'foo', 'arglebargle.txt'
      }.to raise_error Colore::FileNotFound
    end

    it 'raises FileNotFound for an invalid filename' do
      expect {
        document.get_file 'v001', 'text/plain; charset=us-ascii'
      }.to raise_error Colore::FileNotFound
    end
  end

  describe '#to_hash' do
    it 'runs' do
      testhash = JSON.parse(File.read(fixture('document.json')))
      testhash = Colore::Utils.symbolize_keys testhash
      dochash = Colore::Utils.symbolize_keys document.to_hash
      dochash[:versions].each do |k, v|
        v.each { |k1, v1| v1.delete :created_at }
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
      expect(File.exist?(document.directory + 'metadata.json')).to eq true
      # expect this to pass
      JSON.parse File.read(document.directory + 'metadata.json')
    end
  end
end
