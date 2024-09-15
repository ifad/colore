# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Colore::LegacyConverter do
  let(:storage_dir) { tmp_storage_dir }
  let(:content) { 'The brown fox quits' }
  let(:new_format) { 'pdf' }
  let(:converter) { described_class.new }

  before do
    setup_storage
    allow(Colore::C_).to receive(:storage_directory) { tmp_storage_dir }
    stubbed_converter = instance_double(Heathen::Converter, convert: "The quick brown fox")
    allow(Heathen::Converter).to receive(:new).and_return(stubbed_converter)
  end

  after do
    delete_storage
  end

  describe '#convert_file' do
    it 'runs' do
      new_filename = converter.convert_file new_format, content
      expect(new_filename).not_to be_nil
      expect((storage_dir + new_filename).file?).to be true
      stored_content = File.read(storage_dir + new_filename)
      expect(stored_content).to eq 'The quick brown fox'
    end
  end

  describe '#store_file' do
    it 'runs' do
      filename = 'foo.txt'
      content = 'The quick brown fox'
      converter.store_file filename, content
      expect((converter.legacy_dir + filename).file?).to be true
      expect(File.read(converter.legacy_dir + filename)).to eq content
    end
  end

  describe '#get_file' do
    it 'runs' do
      filename = converter.convert_file new_format, content
      expect(converter.get_file(File.basename(filename))).to eq 'The quick brown fox'
    end
  end
end
