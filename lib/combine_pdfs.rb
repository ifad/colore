class CombinePdfs
  def call(pdfs)
    combined_pdf = CombinePDF.new

    pdfs.each {|pdf| combined_pdf << CombinePDF.parse(pdf) }

    combined_pdf.to_pdf
  end
end