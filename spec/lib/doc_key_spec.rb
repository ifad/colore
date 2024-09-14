# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Colore::DocKey do
  let(:doc_key) { described_class.new('myapp', 'mydoc') }

  describe '.initialize' do
    it 'throws error if app is invalid' do
      expect { described_class.new 'my app', 'mydoc' }.to raise_error(Colore::InvalidParameter)
    end

    it 'throws error if doc_id is invalid' do
      expect { described_class.new 'myapp', 'my doc' }.to raise_error(Colore::InvalidParameter)
    end
  end

  describe '#path' do
    it 'runs' do
      expect(doc_key.path).to be_a Pathname
    end
  end

  describe '#to_s' do
    it 'runs' do
      expect(doc_key.to_s).to eq 'myapp/mydoc'
    end
  end

  describe '#subdirectory' do
    it 'runs' do
      expect(doc_key.subdirectory).to eq 'd8'
    end
  end
end
