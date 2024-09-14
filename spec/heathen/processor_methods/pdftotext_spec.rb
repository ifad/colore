require 'spec_helper'

RSpec.describe Heathen::Processor do
  let(:content) { fixture('heathen/quickfox.pdf').read }
  let(:job) { Heathen::Job.new 'foo', content, 'en' }
  let(:processor) { described_class.new job: job, logger: Logger.new($stderr) }

  after do
    processor.clean_up
  end

  describe '#pdftotext' do
    it 'converts PDF to TXT' do
      processor.pdftotext
      expect(job.content.mime_type).to eq 'text/plain; charset=us-ascii'
    end
  end
end
