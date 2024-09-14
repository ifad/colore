# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Heathen::Processor do
  let(:content) { fixture('heathen/quickfox.jpg').read }
  let(:job) { Heathen::Job.new 'foo', content, 'en' }
  let(:processor) { described_class.new job: job, logger: spec_logger }

  after do
    processor.clean_up
  end

  describe '#convert_image' do
    it 'converts to tiff' do
      processor.convert_image to: :tiff, params: '-density 72'
      expect(job.content.mime_type).to eq 'image/tiff; charset=binary'
    end
  end
end
