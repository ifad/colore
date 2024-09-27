# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'pathname'

RSpec.describe Colore::TikaConfig do
  let(:tika_config_directory) { '../tmp/tika-test' }
  let(:tika_test_config_path) { Pathname.new(File.expand_path('../../tmp/tika-test', __dir__)) }

  before do
    allow(Colore::C_.config).to receive(:tika_config_directory).and_return tika_config_directory
    FileUtils.mkdir_p tika_test_config_path
    FileUtils.rm_rf tika_test_config_path
  end

  after do
    FileUtils.rm_rf tika_test_config_path
  end

  describe '.path_for' do
    subject(:path_for) { described_class.path_for(language) }

    context 'when the language is found' do
      let(:language) { 'fr' }

      before do
        allow(Colore::Utils).to receive(:language_alpha3).with('fr').and_return('fra')
      end

      it 'returns the correct configuration file path' do
        expect(path_for).to eq tika_test_config_path.join('ocr', described_class::VERSION, 'tika.fra.xml')
      end
    end

    context 'when the language is not found' do
      let(:language) { 'unknown' }

      it 'returns the default configuration file path' do
        expect(path_for).to eq tika_test_config_path.join('ocr', described_class::VERSION, "tika.#{described_class::DEFAULT_LANGUAGE}.xml")
      end
    end

    context 'when the configuration file is already present' do
      let(:language) { 'en' }

      before do
        allow(File).to receive(:write)
          .with(tika_test_config_path.join('ocr', described_class::VERSION, 'tika.eng.xml'), an_instance_of(String))
          .and_call_original
      end

      it 'does not overwrite it' do
        2.times { described_class.path_for(language) }
        expect(File).to have_received(:write).once
      end
    end
  end
end
