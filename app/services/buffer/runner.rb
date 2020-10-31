module Buffer
  class Runner

    def initialize(mode)
      @mode = mode
    end

    def run
      Settings.buffers.each do |buffer_setting|
        next if buffer_setting.enabled == false

        reader = Reader.new(buffer_setting.source)

        case buffer_setting.mode
        when 'write_items'
          data = Nokogiri::XML('<data/>')
          reader.read do |items|
            data.root << items
          end
          write_items(data, buffer_setting.filename)

        when 'buffer_related_items'
          reader.read do |items|
            items.each do |object_item|
              buffer_setting.related_item.tap do |related_settings|
                data = Nokogiri::XML::Document.new
                data.add_child(object_item)

                related_item_url = data.root.at_xpath(related_settings.api.endpoint.xsl).value
                filename = data.root.xpath(related_settings.filename.xsl)
                item_reader = Reader.new(related_settings)
                item_for = data.root.at_xpath(related_settings.data_for)

                item_reader.read(related_item_url) do |related_items|
                  item_for << related_items
                end

                write_items(data, filename)
              end
            end
          end
        end
      end
    end

    def write_items(items, filename)
      output_file = File.join(Settings.output, filename)
      output_dir = File.dirname(output_file)
      FileUtils.mkpath(output_dir)
      File.write(output_file, items.to_xml)
    end
  end
end
