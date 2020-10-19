module Buffer
  class Runner

    def initialize(mode)
      @mode = mode
    end

    def run
      Settings.buffers.each do |buffer_setting|
        next if buffer_setting.enabled == false

        data = Nokogiri::XML('<data/>')

        reader = Reader.new(buffer_setting.source)
        reader.read do |items|
          # <api:object category="user"...
          case buffer_setting.mode
          when 'write_items'
            data.root << items
          when 'buffer_related_items'
            items.each do |object_item|
              related_data = Nokogiri::XML('<data/>')

              related_item_url = object_item.at_xpath(buffer_setting.buffer_item.api.endpoint.xsl).value
              filename = object_item.xpath(buffer_setting.buffer_item.filename.xsl)

              item_reader = Reader.new(buffer_setting.buffer_item)
              item_reader.read(related_item_url) do |related_items|
                # <api:relationship id="246137" type-id="8" type="publication-user-authorship"
                related_data.root << related_items
              end
              write_items(related_data, filename)
            end
          end
        end

        if buffer_setting.mode == 'write_items'
          write_items(data, buffer_setting.filename)
        end

        # byebug

        # case buffer_setting.mode
        # when 'write_items'
        #   write_items(reader.items, buffer_setting.filename)
        # when 'buffer_related_items'
        #   puts 'need to do something here for buffer_related_items'
        # end
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
