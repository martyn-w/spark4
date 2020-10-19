require 'fakefs/spec_helpers'
require 'webmock/rspec'

RSpec.describe Buffer::Runner do

  subject(:runner) { described_class.new(mode) }

  describe 'people index' do
    let(:mode) { :full }
    let!(:people_index_xml) { file_fixture('spark-generated/people/index.xml').read }
    let!(:user1_xml) { file_fixture('spark-generated/people/user1.xml').read }
    let!(:user2_xml) { file_fixture('spark-generated/people/user2.xml').read }
    let!(:user3_xml) { file_fixture('spark-generated/people/user3.xml').read }

    before do
      stub_request(:get, 'http://example.test/users?detail=full&per-page=2')
          .to_return(status: 200, body: file_fixture('symplectic-api/users_full_page_1.xml').read, headers: {})

      stub_request(:get, 'http://example.test/users?detail=full&per-page=2&after-id=2')
          .to_return(status: 200, body: file_fixture('symplectic-api/users_full_page_2.xml').read, headers: {})

      stub_request(:get, "http://example.test/users/1/relationships?detail=full&per-page=2").
          to_return(status: 200, body: file_fixture('symplectic-api/user_1_relationships_page_1.xml').read, headers: {})

      stub_request(:get, "http://example.test/users/1/relationships?after-id=246138&detail=full&modified-since=2019-03-01T11:13:36.650&per-page=2").
          to_return(status: 200, body: file_fixture('symplectic-api/user_1_relationships_page_2.xml').read, headers: {})

      stub_request(:get, "http://example.test/users/2/relationships?detail=full&per-page=2").
          to_return(status: 200, body: "", headers: {})

      stub_request(:get, "http://example.test/users/3/relationships?detail=full&per-page=2").
          to_return(status: 200, body: "", headers: {})
    end

    it 'generates a people/index file' do
      FakeFS.with_fresh do
        runner.run
        expect(File.read('data/people/index.xml')).to be_equivalent_to(people_index_xml)
      end
    end

    it 'generates a people/user1 file' do
      FakeFS.with_fresh do
        runner.run
        expect(File.read('data/people/user1.xml')).to be_equivalent_to(user1_xml)
      end
    end

    it 'generates a people/user2 file' do
      FakeFS.with_fresh do
        runner.run
        expect(File.read('data/people/user2.xml')).to be_equivalent_to(user2_xml)
      end
    end

    it 'generates a people/user3 file' do
      FakeFS.with_fresh do
        runner.run
        expect(File.read('data/people/user3.xml')).to be_equivalent_to(user3_xml)
      end
    end
  end
end