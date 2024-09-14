# frozen_string_literal: true

def ms_excel_mime_types
  [
    'application/octet-stream; charset=binary', # LibreOffice 5.1
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet; charset=binary',
    'application/zip; charset=binary', # LibreOffice 6.0.7
  ]
end

def ms_powerpoint_mime_types
  [
    'application/octet-stream; charset=binary', # LibreOffice 6.0.7
    'application/vnd.openxmlformats-officedocument.presentationml.presentation; charset=binary',
  ]
end

def ms_word_mime_types
  [
    'application/octet-stream; charset=binary', # LibreOffice 6.0.7
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document; charset=binary',
    'application/zip; charset=binary',
  ]
end

def oo_odp_mime_types
  ['application/vnd.oasis.opendocument.presentation; charset=binary']
end

def oo_ods_mime_types
  ['application/vnd.oasis.opendocument.spreadsheet; charset=binary']
end

def oo_odt_mime_types
  ['application/vnd.oasis.opendocument.text; charset=binary']
end

def tesseract_hocr_mime_types
  [
    'application/xml; charset=us-ascii', # tesseract v3
    'text/xml; charset=us-ascii', # tesseract v4
  ]
end
