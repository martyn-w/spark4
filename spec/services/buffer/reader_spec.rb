require 'webmock/rspec'

RSpec.describe Buffer::Reader do
  subject(:reader) { described_class.new(buffer_setting) }
  let(:buffer_setting) { Settings.buffers.find{ |b| b.name == buffer_setting_name } }
  # let(:buffer_setting_source) { buffer_setting.source }
  let(:accept) { 'application/atom+xml' }
  let(:authorization) { "Basic #{Base64.strict_encode64('USERNAME:PASSWORD')}" }
  let(:namespaces) { { 'atom': 'http://www.w3.org/2005/Atom', 'api': 'http://www.symplectic.co.uk/publications/api' } }


  describe 'person_index' do
    let(:buffer_setting_name) { 'person_index' }

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

      expect(data).to be_equivalent_to(file_fixture('spark-generated/people/index.xml').read)
    end
  end

  describe 'disabled_buffer' do
    let(:buffer_setting_name) { 'disabled_buffer' }

    it 'throws an error' do
      expect { reader }.to raise_error('Buffer disabled_buffer is not enabled')
    end
  end
end
