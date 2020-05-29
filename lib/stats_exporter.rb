require 'csv'
require 'date'
require 'json'
require 'logger'
require 'active_support'
require 'active_support/core_ext'

class StatsExporter
    def initialize(conf)
        @logger = conf[:logger] ? conf[:logger] : Logger.new(STDERR)
        if (append_path = conf[:append_path])
            @logger.info("Appending searchterms to #{append_path} ...")
            old_stats = JSON.parse(File.read(append_path), {:symbolize_names => true})
            @stats = old_stats[:stats]
            @stats[:site_uri] = conf[:stats][:site_uri]
            @stats[:earliest] = conf[:stats][:earliest]
            @stats[:latest] = conf[:stats][:latest]
            conf[:stats][:months].each do |month, counts|
                @logger.info("Appending searchterm counts for #{month} ...")
                @stats[:months][month.to_sym] = counts
            end
            @stats[:months] = Hash[@stats[:months].sort { |a, b| b <=> a}]
        else
            @logger.info("Overwriting searchterms file ...")
            @stats = conf[:stats]
        end
    end

    def to_json
        {
            :timestamp => Time.now.iso8601 ,
            :source => "Webtrekk" ,
            :stats => @stats
        }
    end

    def StatsExporter.month_limits(month)
        {
            :first => Date.new(month.year, month.month, 1) ,
            :last => month.end_of_month
        }
    end

    def StatsExporter.month_list(start_date, end_date)
        months = []
        current_date = end_date
        while (current_date >= start_date)
            months << StatsExporter.month_limits(current_date)
            current_date = current_date.prev_month
        end
        months
    end

end