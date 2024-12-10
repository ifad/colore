class CombinePdfs
  def call(pdfs)
    combined_pdf = CombinePDF.new
    combined_pdf = pdfs.reduce(combined_pdf) { |combined, pdf| combined << pdf; combined }

    combined_pdf.to_pdf
  end
end