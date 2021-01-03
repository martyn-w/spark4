require 'webmock/rspec'

RSpec.describe Buffer::Reader do
  subject(:reader) { described_class.new(buffer_source, logger) }

  let(:logger) { Logger.new(nil) }
  let(:accept) { 'application/atom+xml' }
  let(:authorization) { "Basic #{Base64.strict_encode64('USERNAME:PASSWORD')}" }
  let(:namespaces) { { 'atom': 'http://www.w3.org/2005/Atom', 'api': 'http://www.symplectic.co.uk/publications/api' } }

  describe 'users' do
    let(:buffer_source) { find_buffer('person_index').source }

    before do
      stub_request(:get, 'http://example.test/users?detail=full&per-page=2')
        .with(headers: { 'Accept' => accept, 'Authorization' => authorization })
        .to_return(status: 200, body: file_fixture('symplectic-api/users_full_page_1.xml').read, headers: {})

      stub_request(:get, 'http://example.test/users?detail=full&per-page=2&after-id=2')
        .with(headers: { 'Accept' => accept, 'Authorization' => authorization })
        .to_return(status: 200, body: file_fixture('symplectic-api/users_full_page_2.xml').read, headers: {})
    end

    it 'fetches all pages and extracts all the objects' do
      data = Nokogiri::XML('<data/>')

      reader.read do |items|
        data.root << items
      end

      expect(data).to be_equivalent_to(file_fixture('spark-generated/person/index.xml').read)
    end
  end

  describe 'users.related_items' do
    let(:buffer_source) { find_buffer('person').related_item }

    before do
      stub_request(:get, "http://example.test/users/1/relationships?detail=full&per-page=2").
          with(headers: { 'Accept'=> accept, 'Authorization'=>authorization }).
          to_return(status: 200, body: file_fixture('symplectic-api/user_1_relationships_page_1.xml').read, headers: {})

      stub_request(:get, "http://example.test/users/1/relationships?after-id=246138&detail=full&modified-since=2019-03-01T11:13:36.650&per-page=2").
          with(headers: { 'Accept'=> accept, 'Authorization'=>authorization }).
          to_return(status: 200, body: file_fixture('symplectic-api/user_1_relationships_page_2.xml').read, headers: {})
    end

    it 'fetches all pages and extracts all the objects' do
      data = Nokogiri::XML('<api:relationships/>')

      reader.read('users/1/relationships') do |items|
        data.root << items
      end

      expect(data).to be_equivalent_to(file_fixture('spark-generated/relationships/user1.xml').read)
    end
  end
end

def find_buffer(buffer_name)
  Settings.buffers.find{ |b| b.name == buffer_name }
end
