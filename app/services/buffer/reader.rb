require 'faraday'
require 'nokogiri'

module Buffer
  class Reader
    DEFAULT_TIMEOUT = 5
    HEADERS = { Accept: 'application/atom+xml' }
    NAMESPACES = { 'atom': 'http://www.w3.org/2005/Atom', 'api': 'http://www.symplectic.co.uk/publications/api' }

    attr_reader :source, :connection, :current_page, :logger

    def initialize(source, logger)
      @source = source
      @connection = build_connection
      @current_page = nil
      @logger = logger
    end

    def read(endpoint = nil, &block)
      if source.api.present?
        read_from_api(endpoint || source.api.endpoint, &block)
      elsif source.filename.present?
        read_from_file(source.filename, &block)
      end
    end

    # the block will be called with the current page of data
    def read_from_api(endpoint, &block)
      # first page
      fetch_page(endpoint, first_page_params)
      yield current_items if block_given?

      # subsequent pages (if any)
      while has_next_page?
        sleep(rand(0.25))
        fetch_page(next_page_url)
        yield current_items if block_given?
      end
    end

    def read_from_file(filename, &block)
      xml_file = File.join(Settings.output, filename)
      raise "File not found: #{xml_file}" unless File.exists?(xml_file)

      items = Nokogiri::XML(File.read(xml_file)).xpath(source.select, NAMESPACES)
      yield items if block_given?
    end

    private

    def build_connection
      Faraday.new(Settings.api.url, request: { timeout: Settings.api.timeout || DEFAULT_TIMEOUT }) do |conn|
        conn.basic_auth(Settings.api.username, Settings.api.password) if Settings.api.username.present?
        conn.request(:retry, Settings.api.retries.to_h) if Settings.api.retries.present? # automatically retry requests if timeout
      end
    end

    def fetch_page(endpoint, params = nil)
      response = connection.get(endpoint, params, HEADERS)

      raise "Error retrieving data from api #{endpoint}" unless response.success?

      @current_page = Nokogiri::XML(response.body)
    end

    def current_items
      current_page.xpath(source.select, NAMESPACES)
    end

    def first_page_params
      source.api.params.to_h
    end

    def next_page_url
      current_page.at_xpath('/atom:feed/api:pagination/api:page[@position="next"]/@href', NAMESPACES)&.value if current_page.present?
    end

    def has_next_page?
      next_page_url.present?
    end
  end
end
