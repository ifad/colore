# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Heathen::Processor do
  let(:content) { fixture('heathen/quickfox.html').read }
  let(:job) { Heathen::Job.new 'foo', content, 'en' }
  let(:processor) { described_class.new job: job, logger: spec_logger }

  after do
    processor.clean_up
  end

  describe '#wkhtmltopdf' do
    it 'converts HTML to PDF' do
      processor.wkhtmltopdf
      expect(job.content.mime_type).to eq 'application/pdf; charset=binary'
    end
  end
end
