# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'pathname'

RSpec.describe Colore::TikaConfig do
  before do
    setup_tika_config
  end

  after do
    delete_tika_config
  end

  describe '.path_for' do
    subject(:path_for) { described_class.path_for(language) }

    context 'when the language is found' do
      let(:language) { 'fr' }

      before do
        allow(Colore::Utils).to receive(:language_alpha3).with('fr').and_return('fra')
      end

      it 'returns the correct configuration file path' do
        expect(path_for).to eq tmp_tika_config_dir.join('ocr', described_class::VERSION, 'tika.fra.xml')
      end
    end

    context 'when the language is not found' do
      let(:language) { 'unknown' }

      it 'returns the default configuration file path' do
        expect(path_for).to eq tmp_tika_config_dir.join('ocr', described_class::VERSION, "tika.#{described_class::DEFAULT_LANGUAGE}.xml")
      end
    end

    context 'when the configuration file is already present' do
      let(:language) { 'en' }

      before do
        allow(FileUtils).to receive(:mkdir_p)
          .with(tmp_tika_config_dir.join('ocr', described_class::VERSION))
          .and_call_original
      end

      it 'does not overwrite it' do
        2.times { described_class.path_for(language) }
        expect(FileUtils).to have_received(:mkdir_p).once
      end
    end
  end

  describe '.path_for_language_detection' do
    subject(:path_for_language_detection) { described_class.path_for_language_detection }

    it 'returns the correct configuration file path' do
      expect(path_for_language_detection).to eq tmp_tika_config_dir.join('ocr', described_class::VERSION, 'tika.eng.xml')
    end

    context 'when multiple languages are available' do
      before do
        allow(Colore::C_.config).to receive(:tesseract_available_languages).and_return(%w[fra eng])
      end

      it 'returns the correct configuration file path' do
        expect(path_for_language_detection).to eq tmp_tika_config_dir.join('ocr', described_class::VERSION, 'tika.eng-fra.xml')
      end
    end
  end
end
