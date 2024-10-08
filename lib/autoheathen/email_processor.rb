# frozen_string_literal: true

require 'filemagic/ext'
require 'haml'
require 'logger'
require 'mail'
require 'pathname'
require 'yaml'

module AutoHeathen
  class EmailProcessor
    include AutoHeathen::Config

    # The only valid email headers we will allow forward to LEG_wikilex
    ONWARD_HEADERS = ['Date', 'From', 'To', 'Subject', 'Content-Type', 'Content-Transfer-Encoding', 'Mime-Version']

    attr_reader :cfg, :logger

    # Constructs the processor
    # @param cfg a hash of configuration settings:
    #    deliver:          true                           If false, email will not be actually sent (useful for testing)
    #    email:            nil                            Email to send response to (if mode == :email)
    #    from:             'autoheathen'                  Who to say the email is from
    #    cc_blacklist:     nil                            Array of email addresses to excise from CC list of any mails
    #                                                     - used to avoid infinite loops in autoheathen
    #    mail_host:        'localhost'                    Mail relay host for responses (mode in [:return_to_sender,:email]
    #    mail_port:        25                             Mail relay port (ditto)
    #    text_template:    'config/response.text.haml'    Template for text part of response email (mode in [:return_to_sender,:email])
    #    html_template:    'config/response.html.haml'    Template for HTML part of response email (ditto)
    #    logger:           nil                            Optional logger object
    def initialize(cfg = {}, config_file = nil)
      @cfg = load_config({ # defaults
          deliver:          true,
          language:         'en',
          from:             'autoheathen',
          cc_blacklist:     nil,
          email:            nil,
          verbose:          false,
          mail_host:        'localhost',
          mail_port:        25,
          logger:           nil,
          text_template:    'config/autoheathen.text.haml',
          html_template:    'config/autoheathen.html.haml',
        }, config_file, cfg)
      @logger = @cfg[:logger] || Logger.new(nil)
      @logger.level = @cfg[:verbose] ? Logger::DEBUG : Logger::INFO
    end

    def process_rts(email)
      process email, email.from, true
    end

    # Processes the given email, submits attachments to the Heathen server, delivers responses as configured
    # @param email [String] The encoded email (suitable to be decoded using Mail.read(input))
    # @return [Hash] a hash of the decoded attachments (or the reason why they could not be decoded)
    def process(email, mail_to, is_rts = false)
      documents = []

      unless email.has_attachments?
        logger.info "From: #{email.from} Subject: (#{email.subject}) Files: no attachments"
        return
      end

      logger.info "From: #{email.from} Subject: (#{email.subject}) Files: #{email.attachments.map(&:filename).join(',')}"

      #
      # Convert the attachments
      #
      email.attachments.each do |attachment|
        converter = Heathen::Converter.new(logger: logger)
        language = @cfg[:language]
        input_source = attachment.body.decoded
        action = get_action input_source.content_type
        logger.info "    convert #{attachment.filename} using action: #{action}"
        data = converter.convert action, input_source, language
        converted_filename = Heathen::Filename.suggest attachment.filename, data.mime_type
        documents << { orig_filename: attachment.filename, orig_content: input_source, filename: converted_filename, content: data, error: false }
      rescue StandardError => e
        documents << { orig_filename: attachment.filename, orig_content: input_source, filename: nil, content: nil, error: e.message }
      end

      #
      # deliver the results
      #
      if is_rts
        deliver_rts email, documents, mail_to
      else
        deliver_onward email, documents, mail_to
      end

      #
      # Summarise the processing
      #
      logger.info "Results of conversion"
      documents.each do |doc|
        if doc[:content].nil?
          logger.info "  #{doc[:orig_filename]} was not converted (#{doc[:error]}) "
        else
          logger.info "  #{doc[:orig_filename]} was converted successfully"
        end
      end

      documents
    end

    # Forward the email to sender, with decoded documents replacing the originals
    def deliver_onward(email, documents, mail_to)
      logger.info "Sending response mail to #{mail_to}"
      email.cc [] # No CCing, just send to the recipient
      email.to mail_to
      email.subject "#{'Fwd: ' unless email.subject.to_s.start_with? 'Fwd:'}#{email.subject}"
      email.return_path email.from unless email.return_path
      # something weird goes on with Sharepoint, where the doc is dropped on the floor
      # so, remove any offending headers
      email.message_id = nil # make sure of message_id too
      good_headers = ONWARD_HEADERS.map { |h| h.downcase }
      inspect_headers = email.header.map(&:name)
      inspect_headers.each do |name|
        unless good_headers.include? name.downcase
          email.header[name] = nil
        end
      end
      email.received = nil # make sure of received
      # replace attachments with converted files
      email.parts.delete_if { |p| p.attachment? }
      documents.each do |doc|
        if doc[:content]
          email.add_file filename: doc[:filename], content: doc[:content]
        else # preserve non-converted attachments when forwarding
          email.add_file filename: doc[:orig_filename], content: doc[:orig_content]
        end
      end
      email.delivery_method :smtp, address: @cfg[:mail_host], port: @cfg[:mail_port]
      deliver email
    end

    # Send decoded documents back to sender
    def deliver_rts(email, documents, mail_to)
      logger.info "Sending response mail to #{mail_to}"
      mail = Mail.new
      mail.from @cfg[:from]
      mail.to mail_to
      # CCs to the original email will get a copy of the converted files as well
      mail.cc (email.cc - email.to - (@cfg[:cc_blacklist] || [])) if email.cc # Prevent autoheathen infinite loop!
      # Don't prepend yet another Re:
      mail.subject "#{'Re: ' unless email.subject.start_with? 'Re:'}#{email.subject}"
      # Construct received path
      # TODO: is this in the right order?
      # rcv = "by localhost(autoheathen); #{Time.now.strftime '%a, %d %b %Y %T %z'}"
      # [email.received,rcv].flatten.each { |rec| mail.received rec.to_s }
      mail.return_path email.return_path if email.return_path
      mail.header['X-Received'] = email.header['X-Received'] if email.header['X-Received']
      documents.each do |doc|
        next if doc[:content].nil?

        mail.add_file filename: doc[:filename], content: doc[:content]
      end
      cfg = @cfg # stoopid Mail scoping
      me = self # stoopid Mail scoping
      mail.text_part do
        s = Haml::Template.new { me.read_file cfg[:text_template] }.render(Object.new, to: mail_to, documents: documents, cfg: cfg)
        body s
      end
      mail.html_part do
        content_type 'text/html; charset=UTF-8'
        s = Haml::Template.new { me.read_file cfg[:html_template] }.render(Object.new, to: mail_to, documents: documents, cfg: cfg)
        body s
      end
      mail.delivery_method :smtp, address: @cfg[:mail_host], port: @cfg[:mail_port]
      deliver mail
    end

    # Convenience method allowing us to stub out actual mail delivery in RSpec
    def deliver(mail)
      if @cfg[:deliver]
        mail.deliver!
        logger.debug "Files were emailed to #{mail.to}"
      else
        logger.debug "Files would have been emailed to #{mail.to}, but #{self.class.name} is configured not to"
      end
    end

    # Opens and reads a file, first given the filename, then tries from the project base directory
    def read_file(filename)
      f = filename
      unless File.exist? f
        f = Pathname.new(__FILE__).realpath.parent.parent.parent + f
      end
      File.read f
    end

    # Returns the correct conversion action based on the content type
    # @raise RuntimeError if there is no conversion action for the content type
    def get_action(content_type)
      ct = content_type.gsub(/;.*/, '')
      op = {
        'application/pdf' => 'ocr',
        'text/html' => 'pdf',
        'application/zip' => 'pdf',
        'application/msword' => 'pdf',
        'application/vnd.oasis.opendocument.text' => 'pdf',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => 'pdf',
        'application/vnd.ms-excel' => 'pdf',
        'application/vnd.ms-office' => 'pdf',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => 'pdf',
        'application/vnd.ms-powerpoint' => 'pdf',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation' => 'pdf',
      }[ct]
      op = 'ocr' if !op && ct.start_with?('image/')
      raise "Conversion from #{ct} is not supported" unless op

      op
    end
  end
end
