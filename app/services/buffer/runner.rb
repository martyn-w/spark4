module Buffer
  class Runner
    require 'yaml'

    attr_reader :logger, :sync_filename

    def initialize(mode, logger = nil)
      @mode = mode
      @logger = logger || get_logger
      @sync_filename = File.join(Settings.output, 'sync.yml')
    end

    def run
      logger.info "Synchronising with: #{Settings.api.url} and outputing to #{Settings.output}"
      latest_timestamp = read_sync_timestamp
      logger.info "Latest sync timestamp: #{latest_timestamp}"

      next_timestamp = DateTime.now
      item_count = 0

      Settings.buffers.each do |buffer_setting|
        next if buffer_setting.enabled == false

        logger.info "Reading #{buffer_setting.name}"

        reader = Reader.new(buffer_setting.source, logger)

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
              begin
                buffer_setting.related_item.tap do |related_settings|
                  object_last_affected = DateTime.parse(object_item.get_attribute('last-affected-when')) rescue nil
                  related_data_filename = object_item.xpath(related_settings.filename.xsl)

                  # only fetch the related data if it is newer than latest_timestamp or doesn't already exist
                  if latest_timestamp.nil? || object_last_affected.nil? || !output_file_exists?(related_data_filename) || latest_timestamp < object_last_affected

                    item_count += 1
                    data = Nokogiri::XML::Document.new
                    data.add_child(object_item)

                    related_item_url = data.root.at_xpath(related_settings.api.endpoint.xsl).value

                    item_reader = Reader.new(related_settings, logger)
                    item_for = data.root.at_xpath(related_settings.data_for)

                    item_reader.read(related_item_url) do |related_items|
                      item_for << related_items
                    end

                    write_items(data, related_data_filename, "(last affected #{object_last_affected})")
                  else
                    logger.info "Skipping #{related_data_filename} (last affected #{object_last_affected})"
                  end
                end
              rescue => ex
                logger.error("Failed to buffer related items: #{ex.inspect}")
                logger.debug(object_item.get_attribute('href')) rescue nil
              end
            end
          end
        end
      end

      write_sync_timestamp(next_timestamp)

      logger.info "All done (#{item_count} items fetched)"
    end


    def read_sync_timestamp
      DateTime.parse(YAML.load_file(sync_filename)[:timestamp]) if File.exists?(sync_filename)
    end

    def write_sync_timestamp(timestamp)
      logger.info "Updating sync timestamp: #{timestamp.iso8601}"
      File.open(sync_filename, 'w') { |file| file.write({timestamp: timestamp.iso8601}.to_yaml) }
    end

    def write_items(items, filename, log_details = nil)
      output_file = File.join(Settings.output, filename)
      output_dir = File.dirname(output_file)
      FileUtils.mkpath(output_dir)
      if log_details.present?
        logger.info("Writing #{output_file} #{log_details}")
      else
        logger.info("Writing #{output_file}")
      end

      File.write(output_file, items.to_xml)
    end

    def output_file_exists?(filename)
      File.exists?(File.join(Settings.output, filename))
    end

    def get_logger
      if Settings.log.present?
        log = Logger.new(Settings.log.filename, Settings.log.shift_age, Settings.log.shift_size)
        log.datetime_format = Settings.log.datetime_format
      else
        log = Logger.new(STDOUT)
      end
      log
    end
  end
end
