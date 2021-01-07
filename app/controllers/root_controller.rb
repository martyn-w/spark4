class RootController < ApplicationController
  before_action do
    @sync_filename ||= File.join(Settings.output, 'sync.yml')
    @last_updated ||= DateTime.parse(YAML.load_file(@sync_filename)[:timestamp]).httpdate if File.exists?(@sync_filename) rescue nil
  end

  def index

  end
end
