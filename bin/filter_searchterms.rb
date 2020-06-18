require 'csv'
require 'json'
require 'logger'

require_relative '../lib/personal_data_filter.rb'

if ARGV.length != 5
    puts "usage: ruby #{ __FILE__} UNFILTERED_IN.json FILTERED_OUT.json REJECTED.csv BLOCKLIST.json ALLOWLIST.json"
    exit
end

unfiltered_path = ARGV[0]
filtered_path = ARGV[1]
rejected_path = ARGV[2]
blocklist_path = ARGV[3]
allowlist_path = ARGV[4]

logger = Logger.new(STDERR)
filter = PersonalDataFilter.new( {
    :blocklist_path => blocklist_path ,
    :allowlist_path => allowlist_path ,
    :logger => logger
})

data = JSON.parse(File.read(unfiltered_path), { :symbolize_names => true })
CSV.open(rejected_path, "wb") do |csv|
    csv << [ "month", "term", "rejection_type" ]
    data[:stats][:months].each do |month, monthdata|
        deleted = []
        monthdata[:terms].each do |term, stats|
            unless filter.allowed?(term.to_s)
                data[:stats][:months][month][:terms].delete(term)
                csv << [ month, term, filter.rejection_type ]
                deleted << { 
                    :term => term ,
                    :rejection_type => filter.rejection_type
                }
            end
        end
        monthdata[:removed_items] = {
            :comment => "Removed #{deleted.length} searchterms as potentially personal information." ,
            :count => deleted.length
        }
    end
end

File.open(filtered_path, "wb") do |f|
    f.write(JSON.pretty_generate(data))
end
