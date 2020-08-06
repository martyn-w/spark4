require 'fakefs/spec_helpers'
require 'webmock/rspec'

RSpec.describe Buffer::Runner do

  subject(:runner) { described_class.new(mode) }

  describe 'people index' do
    let(:mode) { :full }
    let(:expected_people_index) do
      "<?xml version=\"1.0\"?>\n"+
          "<data>\n" +
          "  <api:object xmlns:api=\"http://www.symplectic.co.uk/publications/api\" id=\"1\">First</api:object>\n" +
          "  <api:object xmlns:api=\"http://www.symplectic.co.uk/publications/api\" id=\"2\">Second</api:object>\n" +
          "  <api:object xmlns:api=\"http://www.symplectic.co.uk/publications/api\" id=\"3\">Third</api:object>\n" +
          "</data>\n"
    end

    before do
      # allow(Buffer::Reader).to receive(:new) { reader }
    end

    before do
      stub_request(:get, 'http://example.test/users?detail=full&per-page=2')
          .to_return(status: 200, body: file_fixture('users_full_page_1.xml').read, headers: {})

      stub_request(:get, 'http://example.test/users?detail=full&per-page=2&after-id=2')
          .to_return(status: 200, body: file_fixture('users_full_page_2.xml').read, headers: {})

      stub_request(:get, "http://example.test/users/1/relationships?detail=full&per-page=2").
          to_return(status: 200, body: file_fixture('user_1_relationships_page_1.xml').read, headers: {})

      stub_request(:get, "http://example.test/users/1/relationships?after-id=246138&detail=full&modified-since=2019-03-01T11:13:36.650&per-page=2").
          to_return(status: 200, body: file_fixture('user_1_relationships_page_2.xml').read, headers: {})

      stub_request(:get, "http://example.test/users/2/relationships?detail=full&per-page=2").
          to_return(status: 200, body: "", headers: {})

      stub_request(:get, "http://example.test/users/3/relationships?detail=full&per-page=2").
          to_return(status: 200, body: "", headers: {})



    end

    it 'generates a person/index file' do
      # FakeFS.with_fresh do
        runner.run

        expect(File).to exist('data/people/index.xml')
        # expect(File.read('data/person/index.xml')).to eql expected_people_index
      # end
    end



  end
end