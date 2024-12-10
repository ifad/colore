# frozen_string_literal: true

require 'spec_helper'
require 'app'

RSpec.describe CombinePdfs do
	subject(:combine_pdfs) { CombinePdfs.new.(pdfs) }
	let(:pdfs) { [fixture('pdfs/1.pdf').read, fixture('pdfs/2.pdf').read] }

  describe 'combine' do
    it 'creates a new pdf' do
    	expect {
    		pdf = combine_pdfs
    		expect(pdf.size).to be > 0
    	}.not_to raise_error
    end
  end
end
