require 'json'
require 'logger'

class PersonalDataFilter

    attr_reader :blacklist, :rejection_type

    def initialize(conf)
        @logger = conf[:logger] ? conf[:logger] : Logger.new(STDERR)

        @filters = [
            :in_blacklist?
        ]

        @logger.info("reading blacklist file from #{conf[:blacklist_path]} ...")
        @blacklist = JSON.parse(File.read(conf[:blacklist_path]))
        @blacklist_flat = @blacklist.values.flatten
        @logger.info("read #{@blacklist_flat.length} terms ...")
        @logger.info("reading whitelist file from #{conf[:whitelist_path]} ...")
        @whitelist = JSON.parse(File.read(conf[:whitelist_path]))
        @whitelist_flat = @whitelist.values.map{ |entry| entry["variants"] }.flatten
        @logger.info("read #{@whitelist_flat.length} terms ...")

        @rejection_type = nil
    end

    def in_blacklist?(string)
        @blacklist_flat.include?(string)
    end

    def in_whitelist?(string)
        @whitelist_flat.include?(string)
    end

    def allowed?(string)
        return true if in_whitelist?(string)
        @filters.each do |_filter|
            if send(_filter, string)
                @rejection_type = _filter.to_s
                return false
            end
        end
        true
    end

end