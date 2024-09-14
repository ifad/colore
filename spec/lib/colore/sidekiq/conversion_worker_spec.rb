# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Colore::Sidekiq::ConversionWorker do
  let(:doc_key) { Colore::DocKey.new('app', '12345') }
  let(:callback_url) { 'http://foo/bar' }
  let(:converter) { instance_double(Colore::Converter, convert: true) }

  before do
    allow(Colore::Converter).to receive(:new).and_return(converter)
    allow(Colore::Sidekiq::CallbackWorker).to receive(:perform_async)
  end

  describe '#perform' do
    it 'runs' do
      described_class.new.perform doc_key.to_s, 'current', 'arglebargle.docx', 'pdf', callback_url

      expect(Colore::Sidekiq::CallbackWorker).to have_received(:perform_async)
      expect(converter).to have_received(:convert)
    end

    it 'gives up on Heathen::TaskNotFound' do
      allow(converter).to receive(:convert).and_raise Heathen::TaskNotFound.new('foo', 'bar')

      described_class.new.perform doc_key.to_s, 'current', 'arglebargle.docx', 'pdf', callback_url

      expect(Colore::Sidekiq::CallbackWorker).to have_received(:perform_async)
    end

    it 'gives up on other errors' do
      allow(converter).to receive(:convert).and_raise 'arglebargle'

      described_class.new.perform doc_key.to_s, 'current', 'arglebargle.docx', 'pdf', callback_url

      expect(Colore::Sidekiq::CallbackWorker).to have_received(:perform_async)
    end
  end
end
