require 'open-uri'
require 'nokogiri'

RSpec.describe BufferSettings do
  let(:namespaces) {
    { 'atom': 'http://www.w3.org/2005/Atom', 'api': 'http://www.symplectic.co.uk/publications/api' }
  }

  it 'foo' do
    puts 'hello'

    # url = 'https://lilliput.symplectic.co.uk:8097/secure-api/v5.5/users?per-page=50&detail=single-record'
    # txt = URI.open(url, http_basic_authentication: ['XXXX', 'XXXX'])

    # feed = FeedParser::Parser.parse( File.read('tmp/users.xml') )

    doc = Nokogiri::XML(File.read('tmp/users.xml'))
    doc.xpath('/atom:feed/atom:entry/api:object', namespaces).first.attribute('username').value



    byebug
  end
end