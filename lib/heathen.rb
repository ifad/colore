# frozen_string_literal: true

require 'filemagic/ext'
require 'pathname'

require_relative 'heathen/errors'
require_relative 'heathen/filename'
require_relative 'heathen/job'
require_relative 'heathen/task'
require_relative 'heathen/converter'
require_relative 'heathen/executioner'
require_relative 'heathen/processor'

require_relative 'heathen/processor_methods/convert_image'
require_relative 'heathen/processor_methods/detect_language'
require_relative 'heathen/processor_methods/htmltotext'
require_relative 'heathen/processor_methods/libreoffice'
require_relative 'heathen/processor_methods/pdftotext'
require_relative 'heathen/processor_methods/tesseract'
require_relative 'heathen/processor_methods/wkhtmltopdf'
