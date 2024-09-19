# frozen_string_literal: true

require 'spec_helper'
require 'utils'

RSpec.describe Colore::Utils do
  describe '.symbolize_keys' do
    it 'symbolizes hash' do
      h = {
        name: 'Fred',
        'address' => {
          'house_number' => 12,
          'street' => 'Foo st',
          city: 'Boston',
          phone_numbers: [1234567, '1234567'],
        },
        'rank' => 'Constable',
        'awards' => [
          { type: 'Medal of Honour', 'reason' => 'Stupidity' },
          { 'type' => 'George Cross', reason: 'Bravery' },
        ],
      }
      expect(described_class.symbolize_keys(h)).to eq({
        name: 'Fred',
        address: {
          house_number: 12,
          street: 'Foo st',
          city: 'Boston',
          phone_numbers: [1234567, '1234567'],
        },
        rank: 'Constable',
        awards: [
          { type: 'Medal of Honour', reason: 'Stupidity' },
          { type: 'George Cross', reason: 'Bravery' },
        ],
      })
    end

    it 'symbolizes array' do
      expect(described_class.symbolize_keys([1234, 'fred'])).to contain_exactly(1234, 'fred')
    end

    it 'symbolizes fixnum' do
      expect(described_class.symbolize_keys(1234)).to eq 1234
    end

    it 'symbolizes metadata' do
      h = {
        id: 'id foo',
        app: 'app foo',
        filename: 'filename foo',
        converted: true,
        created_by: 'created_by foo',
        created_at: Time.now,
        versions: {
          original: {
            content_type: 'text/plain',
            filename: 'foo.txt',
          },
          converted: {
            content_type: 'application/pdf',
            filename: 'foo.pdf',
          },
        },
      }
      expect(described_class.symbolize_keys(h)).to eq h
    end
  end
end
