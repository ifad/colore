# frozen_string_literal: true

require 'spec_helper'
require 'autoheathen'
require 'tempfile'

RSpec.describe AutoHeathen::Config do
  let(:klass) { Class.new { include AutoHeathen::Config } }
  let(:obj) { klass.new }
  let(:tempfile) { Tempfile.new 'spectest' }

  after do
    tempfile.unlink
  end

  it "loads config with no defaults" do
    cfg = obj.load_config nil, nil, { 'cow' => 'overcow', :rat => 'overrat' }
    expect(cfg).to eq({
      cow: 'overcow',
      rat: 'overrat',
    })
  end

  it "loads config from all sources" do
    defaults = { 'foo' => 'fooble', :bar => 'barble', 'bob' => 'bobble', :cow => 'cowble', :rat => 'ratble' }
    tempfile.write({
      'bob' => 'filebob',
      'roger' => 'fileroger',
    }.to_yaml)
    tempfile.close
    cfg = obj.load_config defaults, tempfile.path, { 'cow' => 'overcow', :rat => 'overrat' }
    expect(cfg[:foo]).to eq 'fooble'
    expect(cfg[:bar]).to eq 'barble'
    expect(cfg[:bob]).to eq 'filebob'
    expect(cfg[:roger]).to eq 'fileroger'
    expect(cfg[:cow]).to eq 'overcow'
    expect(cfg[:rat]).to eq 'overrat'
  end

  it "symbolizes keys" do
    in_hash = {
      :dog => 'doggle',
      'cat' => 'cattle',
      'horse' => {
        'duck' => :duckle,
        'fish' => 'fishle',
        'eagle' => %w[the quick brown fox],
      },
    }
    hash = obj.symbolize_keys in_hash
    expect(hash).to eq({
      dog: 'doggle',
      cat: 'cattle',
      horse: {
        duck: :duckle,
        fish: 'fishle',
        eagle: %w[the quick brown fox],
      },
    })
  end
end
