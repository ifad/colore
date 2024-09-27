# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Heathen::Processor do
  let(:content) { fixture('heathen/quickfox.pdf').read }
  let(:job) { Heathen::Job.new 'foo', content, language }
  let(:language) { 'en' }
  let(:processor) { described_class.new job: job, logger: spec_logger }

  after do
    processor.clean_up
  end

  describe '#pdftotext' do
    it 'converts PDF to TXT' do
      processor.pdftotext
      expect(job.content).to eq 'The quick brown fox jumps lazily over the dog'
      expect(job.content.mime_type).to eq 'text/plain; charset=us-ascii'
    end

    context 'with Arabic files' do
      let(:content) { fixture('heathen/quickfox.ar.pdf').read }
      let(:language) { 'ar' }

      it 'extracts Arabic text from images' do
        processor.pdftotext
        expect(job.content).to eq fixture('heathen/quickfox.ar.txt').read.strip.force_encoding(Encoding::ASCII_8BIT)
        expect(job.content.mime_type).to eq 'text/plain; charset=utf-8'
      end
    end
  end
end
