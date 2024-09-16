# frozen_string_literal: true

require 'spec_helper'

require 'rest_client'

RSpec.describe Colore::Sidekiq::CallbackWorker do
  let(:doc_key) { Colore::DocKey.new('app', '12345') }
  let(:callback_url) { 'https://example.org/callback' }

  before do
    setup_storage
    allow(Colore::C_.config).to receive(:storage_directory) { tmp_storage_dir }
  end

  after do
    delete_storage
  end

  describe '#perform' do
    it 'runs' do
      allow(RestClient).to receive(:post)

      described_class.new.perform doc_key.to_s, 'current', 'arglebargle.docx', 'pdf', callback_url, 250, 'foobar'

      expect(RestClient).to have_received(:post).with(callback_url, an_instance_of(Hash))
    end
  end
end
