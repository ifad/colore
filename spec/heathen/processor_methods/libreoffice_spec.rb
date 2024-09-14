# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Heathen::Processor do
  let(:ms_word_content) { fixture('heathen/msword.docx').read }
  let(:ms_spreadsheet_content) { fixture('heathen/msexcel.xlsx').read }
  let(:ms_ppt_content) { fixture('heathen/mspowerpoint.pptx').read }
  let(:oo_word_content) { fixture('heathen/ooword.odt').read }
  let(:oo_spreadsheet_content) { fixture('heathen/oospreadsheet.ods').read }
  let(:oo_presentation_content) { fixture('heathen/oopresentation.odp').read }

  def new_job(content)
    @job = Heathen::Job.new 'foo', content, 'en'
    @processor = described_class.new job: @job, logger: spec_logger
  end

  after do
    @processor.clean_up
  end

  describe '#libreoffice' do
    context 'when converting to PDF' do
      it 'converts from MS word' do
        new_job ms_word_content
        @processor.libreoffice format: 'pdf'
        expect(@job.content.mime_type).to eq 'application/pdf; charset=binary'
      end

      it 'converts from MS spreadsheet' do
        new_job ms_spreadsheet_content
        @processor.libreoffice format: 'pdf'
        expect(@job.content.mime_type).to eq 'application/pdf; charset=binary'
      end

      it 'converts from MS powerpoint' do
        new_job ms_ppt_content
        @processor.libreoffice format: 'pdf'
        expect(@job.content.mime_type).to eq 'application/pdf; charset=binary'
      end

      it 'converts from OO word' do
        new_job oo_word_content
        @processor.libreoffice format: 'pdf'
        expect(@job.content.mime_type).to eq 'application/pdf; charset=binary'
      end

      it 'converts from OO spreadsheet' do
        new_job oo_spreadsheet_content
        @processor.libreoffice format: 'pdf'
        expect(@job.content.mime_type).to eq 'application/pdf; charset=binary'
      end

      it 'converts from OO presentation' do
        new_job oo_presentation_content
        @processor.libreoffice format: 'pdf'
        expect(@job.content.mime_type).to eq 'application/pdf; charset=binary'
      end
    end

    context 'when converting to MS' do
      it 'converts from OO word' do
        new_job oo_word_content
        @processor.libreoffice format: 'msoffice'
        expect(ms_word_mime_types).to include(@job.content.mime_type)
      end

      it 'converts from OO spreadsheet' do
        new_job oo_spreadsheet_content
        @processor.libreoffice format: 'msoffice'
        expect(ms_excel_mime_types).to include(@job.content.mime_type)
      end

      it 'converts from OO presentation' do
        new_job oo_presentation_content
        @processor.libreoffice format: 'msoffice'
        expect(ms_powerpoint_mime_types).to include(@job.content.mime_type)
      end
    end

    context 'when converting to OO' do
      it 'converts from MS word' do
        new_job ms_word_content
        @processor.libreoffice format: 'ooffice'
        expect(oo_odt_mime_types).to include(@job.content.mime_type)
      end

      it 'converts from MS spreadsheet' do
        new_job ms_spreadsheet_content
        @processor.libreoffice format: 'ooffice'
        expect(oo_ods_mime_types).to include(@job.content.mime_type)
      end

      it 'converts from MS powerpoint' do
        new_job ms_ppt_content
        @processor.libreoffice format: 'ooffice'
        expect(oo_odp_mime_types).to include(@job.content.mime_type)
      end
    end

    context 'when converting to TXT' do
      it 'converts from MS word' do
        new_job ms_word_content
        @processor.libreoffice format: 'txt'
        expect(@job.content.mime_type).to eq 'text/plain; charset=us-ascii'
      end

      it 'converts from OO word' do
        new_job oo_word_content
        @processor.libreoffice format: 'txt'
        expect(@job.content.mime_type).to eq 'text/plain; charset=us-ascii'
      end
    end
  end
end
