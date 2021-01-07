require 'fakefs/spec_helpers'
require 'webmock/rspec'

RSpec.describe Buffer::Runner do

  subject(:runner) { described_class.new(mode, logger) }

  let(:logger) { Logger.new(nil) }

  describe 'people index' do
    let(:mode) { :full }
    let!(:person_index_xml) { file_fixture('spark-generated/person/index.xml').read }
    let!(:user1_xml) { file_fixture('spark-generated/person/user1.xml').read }
    let!(:user2_xml) { file_fixture('spark-generated/person/user2.xml').read }
    let!(:user3_xml) { file_fixture('spark-generated/person/user3.xml').read }
    let!(:recent_sync_yaml) { file_fixture('spark-generated/recent-sync.yml').read }
    let!(:old_sync_yaml) { file_fixture('spark-generated/old-sync.yml').read }

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

    it 'generates a person/index file' do
      FakeFS.with_fresh do
        runner.run
        expect(File.read(File.join(Settings.output,'person/index.xml'))).to be_equivalent_to(person_index_xml)
      end
    end

    it 'generates a person/user1 file' do
      FakeFS.with_fresh do
        runner.run
        expect(File.read(File.join(Settings.output,'person/user1.xml'))).to be_equivalent_to(user1_xml)
      end
    end

    it 'generates a person/user2 file' do
      FakeFS.with_fresh do
        runner.run
        expect(File.read(File.join(Settings.output,'person/user2.xml'))).to be_equivalent_to(user2_xml)
      end
    end

    it 'generates a person/user3 file' do
      FakeFS.with_fresh do
        runner.run
        expect(File.read(File.join(Settings.output, 'person/user3.xml'))).to be_equivalent_to(user3_xml)
      end
    end

    describe 'incremental updates' do


      before do
        FakeFS.with_fresh do
          FileUtils.mkdir_p(File.join(Settings.output, 'person'))
          File.write(File.join(Settings.output, 'person/index.xml'), person_index_xml)
          File.write(File.join(Settings.output, 'person/user1.xml'), user1_xml)
          File.write(File.join(Settings.output, 'person/user2.xml'), user2_xml)
          File.write(File.join(Settings.output, 'person/user3.xml'), user3_xml)

          sync_xml

          runner.run
        end
      end

      context 'without a sync.xml file' do
        let(:sync_xml) { nil }

        it 'retrieves the user list' do
          expect(a_request(:get, "http://example.test/users?detail=full&per-page=2")).to have_been_made.times(1)
          expect(a_request(:get, "http://example.test/users?detail=full&per-page=2&after-id=2")).to have_been_made.times(1)
        end

        it 'retrieves the relationships' do
          expect(a_request(:get, "http://example.test/users/1/relationships?detail=full&per-page=2")).to have_been_made.times(1)
          expect(a_request(:get, "http://example.test/users/1/relationships?after-id=246138&detail=full&modified-since=2019-03-01T11:13:36.650&per-page=2")).to have_been_made.times(1)
          expect(a_request(:get, "http://example.test/users/2/relationships?detail=full&per-page=2")).to have_been_made.times(1)
          expect(a_request(:get, "http://example.test/users/3/relationships?detail=full&per-page=2")).to have_been_made.times(1)
        end
      end

      context 'with a recent sync.xml file' do
        let(:sync_xml) { File.write(File.join(Settings.output, 'sync.yml'), recent_sync_yaml) }

        it 'retrieves the user list' do
          expect(a_request(:get, "http://example.test/users?detail=full&per-page=2")).to have_been_made.times(1)
          expect(a_request(:get, "http://example.test/users?detail=full&per-page=2&after-id=2")).to have_been_made.times(1)
        end

        it 'does not retrieve the relationships' do
          expect(a_request(:get, "http://example.test/users/1/relationships?detail=full&per-page=2")).not_to have_been_made
          expect(a_request(:get, "http://example.test/users/1/relationships?after-id=246138&detail=full&modified-since=2019-03-01T11:13:36.650&per-page=2")).not_to have_been_made
          expect(a_request(:get, "http://example.test/users/2/relationships?detail=full&per-page=2")).to have_been_made.times(1)
          expect(a_request(:get, "http://example.test/users/3/relationships?detail=full&per-page=2")).not_to have_been_made
        end
      end

      context 'with an old sync.xml file' do
        let(:sync_xml) { File.write(File.join(Settings.output, 'sync.yml'), old_sync_yaml) }

        it 'retrieves the user list' do
          expect(a_request(:get, "http://example.test/users?detail=full&per-page=2")).to have_been_made.times(1)
          expect(a_request(:get, "http://example.test/users?detail=full&per-page=2&after-id=2")).to have_been_made.times(1)
        end

        it 'retrieves the relationships' do
          expect(a_request(:get, "http://example.test/users/1/relationships?detail=full&per-page=2")).to have_been_made.times(1)
          expect(a_request(:get, "http://example.test/users/1/relationships?after-id=246138&detail=full&modified-since=2019-03-01T11:13:36.650&per-page=2")).to have_been_made.times(1)
          expect(a_request(:get, "http://example.test/users/2/relationships?detail=full&per-page=2")).to have_been_made.times(1)
          expect(a_request(:get, "http://example.test/users/3/relationships?detail=full&per-page=2")).to have_been_made.times(1)
        end
      end
    end
  end
end
