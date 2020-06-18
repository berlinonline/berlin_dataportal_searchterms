require 'json'
require 'logger'

class PersonalDataFilter

    attr_reader :blocklist, :rejection_type

    def initialize(conf)
        @logger = conf[:logger] ? conf[:logger] : Logger.new(STDERR)

        @filters = [
            :in_blocklist?
        ]

        @logger.info("reading blocklist file from #{conf[:blocklist_path]} ...")
        @blocklist = JSON.parse(File.read(conf[:blocklist_path]))
        @blocklist_flat = @blocklist.values.flatten
        @logger.info("read #{@blocklist_flat.length} terms ...")
        @logger.info("reading allowlist file from #{conf[:allowlist_path]} ...")
        @allowlist = JSON.parse(File.read(conf[:allowlist_path]))
        @allowlist_flat = @allowlist.values.map{ |entry| entry["variants"] }.flatten
        @logger.info("read #{@allowlist_flat.length} terms ...")

        @rejection_type = nil
    end

    def in_blocklist?(string)
        @blocklist_flat.include?(string)
    end

    def in_allowlist?(string)
        @allowlist_flat.include?(string)
    end

    def allowed?(string)
        return true if in_allowlist?(string)
        @filters.each do |_filter|
            if send(_filter, string)
                @rejection_type = _filter.to_s
                return false
            end
        end
        true
    end

end