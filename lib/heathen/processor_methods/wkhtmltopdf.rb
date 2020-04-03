require 'nokogiri'

module Heathen
  class Processor
    def wkhtmltopdf params=''
      expect_mime_type 'text/html'

      target_file = temp_file_name
      executioner.execute(
        *[Colore::C_.wkhtmltopdf_path, '-q',
        _wkhtmltopdf_options(job.content),
        params.split(/ +/),
        job.content_file('.html'),
        target_file,
        ].flatten
      )
      raise ConversionFailed.new('PDF converter rejected the request') if executioner.last_exit_status != 0
      job.content = File.read(target_file)
      File.unlink(target_file)
    end

    protected

    def _wkhtmltopdf_options(content)
      html = Nokogiri.parse(content)

      attrs = html.xpath("//meta[starts-with(@name, 'colore')]").inject({}) do |h, meta|
        name  = meta.attributes['name'].value.sub(/^colore/, '-')
        value = if meta.attributes.key?('content')
          unless (v = meta.attributes['content'].value.strip).size.zero?
            v
          end
        end

        h.merge(name => value)
      end

      attrs.inject([]){ |d, (k,v)| d << [k, v] }.flatten.compact
    end
  end
end
