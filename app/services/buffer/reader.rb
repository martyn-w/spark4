require 'faraday'
require 'nokogiri'

module Buffer
  class Reader
    DEFAULT_TIMEOUT = 5
    HEADERS = { Accept: 'application/atom+xml' }
    NAMESPACES = { 'atom': 'http://www.w3.org/2005/Atom', 'api': 'http://www.symplectic.co.uk/publications/api' }

    def initialize(buffer_setting)
      @buffer_setting_source = buffer_setting.source
      @connection = Faraday.new(Settings.api.url, request: { timeout: Settings.api.timeout || DEFAULT_TIMEOUT }) do |conn|
        conn.basic_auth(Settings.api.username, Settings.api.password) if Settings.api.username.present?
        conn.request(:retry, Settings.api.retries.to_h) if Settings.api.retries.present? # automatically retry requests if timeout
      end
      @current_page = nil
    end

    # the block will be called with the current page of data
    def read(endpoint = @buffer_setting_source.api.endpoint, &block)
      # byebug
      # first page
      fetch_page(endpoint, first_page_params)
      yield current_items if block_given?

      # subsequent pages (if any)
      while has_next_page?
        fetch_page(next_page_url)
        yield current_items if block_given?
      end
    end

    private

    def fetch_page(endpoint, params = nil)
      response = @connection.get(endpoint, params, HEADERS)

      raise "Error retrieving data from api #{endpoint}" unless response.success?

      @current_page = Nokogiri::XML(response.body)
    end

    def current_items
      @current_page.xpath(@buffer_setting_source.select, NAMESPACES)
    end

    def first_page_params
      @buffer_setting_source.api.params.to_h
    end

    def next_page_url
      @current_page.at_xpath('/atom:feed/api:pagination/api:page[@position="next"]/@href', NAMESPACES)&.value if @current_page.present?
    end

    def has_next_page?
      next_page_url.present?
    end
  end
end