# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Heathen::Processor do
  let(:content) { fixture('heathen/quickfox.ar.jpg').read }
  let(:job) { Heathen::Job.new 'foo', content }
  let(:processor) { described_class.new job: job, logger: spec_logger }

  before do
    setup_tika_config
  end

  after do
    processor.clean_up
    delete_tika_config
  end

  describe '#detect_language' do
    let(:content) { fixture('heathen/quickfox.jpg').read }
    let(:tesseract_available_languages) { %w[eng] }

    before do
      allow(Colore::C_.config).to receive(:tesseract_available_languages).and_return(tesseract_available_languages)

      processor.detect_language
    end

    it 'detects document language' do
      expect(job.content).to eq 'en'
      expect(job.content.mime_type).to eq 'text/plain; charset=us-ascii'
    end

    context 'with Arabic documents' do
      let(:content) { fixture('heathen/quickfox.ar.jpg').read }

      context 'when Arabic is not available in Tesseract' do
        it 'does not detect Arabic' do
          expect(job.content).not_to eq 'ar'
        end
      end

      context 'when Arabic is available in Tesseract' do
        let(:tesseract_available_languages) { %w[eng ara] }

        it 'detects Arabic' do
          expect(job.content).to eq 'ar'
        end
      end
    end
  end
end
