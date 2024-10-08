# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Heathen::Processor do
  let(:content) { fixture('heathen/quickfox.tiff').read }
  let(:job) { Heathen::Job.new 'foo', content, 'en' }
  let(:processor) { described_class.new job: job, logger: spec_logger }

  after do
    processor.clean_up
  end

  describe '#tesseract' do
    it 'converts a tiff to text' do
      processor.tesseract format: nil
      expect(job.content.mime_type).to eq 'text/plain; charset=us-ascii'
    end

    it 'converts a tiff to PDF' do
      processor.tesseract format: 'pdf'
      expect(job.content.mime_type).to eq 'application/pdf; charset=binary'
    end

    it 'converts a tiff to HOCR' do
      processor.tesseract format: 'hocr'
      expect(tesseract_hocr_mime_types).to include(job.content.mime_type)
    end
  end
end
