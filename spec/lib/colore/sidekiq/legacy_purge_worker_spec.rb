# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Colore::Sidekiq::LegacyPurgeWorker do
  before do
    setup_storage
    allow(Colore::C_.config).to receive(:storage_directory) { tmp_storage_dir }
    allow(Colore::C_.config).to receive(:legacy_purge_days).and_return(2)
  end

  after do
    delete_storage
  end

  describe '#perform' do
    it 'runs' do
      dir = Colore::LegacyConverter.new.legacy_dir
      file1 = dir.join('file1.tiff')
      file2 = dir.join('file2.tiff')
      file1.write('foobar')
      file2.write('foobar')
      described_class.new.perform
      expect(file1).to be_file
      expect(file2).to be_file
      Timecop.freeze(Date.today + 1)
      described_class.new.perform
      expect(file1).to be_file
      expect(file2).to be_file
      Timecop.freeze(Date.today + 3)
      described_class.new.perform
      expect(file1).not_to be_file
      expect(file2).not_to be_file
    end
  end
end
