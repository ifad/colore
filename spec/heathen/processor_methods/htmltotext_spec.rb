# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Heathen::Processor do
  let(:content) { fixture('heathen/quickfox.html').read }
  let(:job) { Heathen::Job.new 'foo', content, 'en' }
  let(:processor) { described_class.new job: job, logger: Logger.new($stderr) }

  after do
    processor.clean_up
  end

  describe '#htmltotext' do
    it 'converts HTML to TXT' do
      processor.htmltotext
      expect(job.content.mime_type).to eq 'text/plain; charset=us-ascii'
    end
  end
end
