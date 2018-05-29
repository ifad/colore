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
            # Some wkhtmltopdf command line options such as `--custom-header KEY VALUE` allows for 2 values as params
            # instead of the regular 1 param. In that case the meta content is splitted by `;` delimiter
            # https://wkhtmltopdf.org/usage/wkhtmltopdf.txt
            #
            # Ex:
            # Let's say we have a report in HTML that needs to be converted into PDF and the report contains some images that
            # are not publicly served but they need credentials. We can let wkhtml2pdf know it needs to send authentication
            # credentials via custom HTML meta headers like
            #
            # <meta name="colore-custom-header" content="X-AUTH-TOKEN;FooBarBaz" />
            # <meta name="colore-custom-header-propagation" />
            #
            # that will arrive to colore as:
            # meta.attributes['content'].value = "X-AUTH-TOKEN;FooBarBaz"
            #
            # and here we are splitting it in 2 keywords so the Executioner will escape them indidually as if we pass them
            # sepparated by ' ' Open3 will send them to wkhtml2pdf as 2 single param enclosed in '""' which will basically be ignored
            v.split ';'
          end
        end

        h.merge(name => value)
      end

      attrs.inject([]){ |d, (k,v)| d << [k, v] }.flatten.compact
    end
  end
end
