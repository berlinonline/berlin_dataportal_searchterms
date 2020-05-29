require 'date'
require 'keychain'
require 'logger'
require 'optparse'
require 'uri'
require 'active_support'
require 'active_support/core_ext'
require 'pp'

require 'webtrekk_connector'
require_relative '../lib/stats_exporter.rb'

logger = Logger.new(STDERR)

options = {
    :endpoint => "https://report27.webtrekk.com/cgi-bin/wt/JSONRPC.cgi" , 
    :month => Date.today.prev_month ,
    :all_months => false ,
    :replace => false ,
}

usage = "Usage: ruby #{ __FILE__} [options] CONF.JSON OUTFILE.JSON"
OptionParser.new do |opts|
  opts.banner = usage
  opts.separator ""
  opts.separator "Options:"

  opts.on("-e", "--endpoint STRING", String, "The domain of the Webtrekk API endpoint. Used for getting password out of keychain.") do |endpoint|
    options[:endpoint] = endpoint
  end

  opts.on("-m", "--months STRING", String, "The month to retrieve. Use YYYY-MM syntax. Defaults to the previous month.") do |month|
    options[:month] = Date.parse("#{month}-01")
  end

  opts.on("-a", "--[no-]all_months", "Get all months (instead of just the --month).") do |all_months|
    options[:all_months] = all_months
  end

  opts.on("-r", "--[no-]replace", "Replace the stats files instead of appending.") do |replace|
    options[:replace] = replace
  end

end.parse!

json_out_file = ARGV.pop
conf_path = ARGV.pop
unless conf_path
  puts usage
  exit
end

config = JSON.parse(File.read(conf_path))

unless File.exist?(json_out_file)
  puts "File #{json_out_file} doesn't exist, cannot append to it."
  exit
end

# get username and password from OS X keychain
keychain_item = Keychain.internet_passwords.where(:server => URI(options[:endpoint]).host).first

unless keychain_item
    puts "No internet password for server #{options[:endpoint]} found, cannot proceed."
    exit
end

options[:user] = keychain_item.account
options[:pwd] = keychain_item.password
options[:logger] = logger

connector = WebtrekkConnector.new(options)
connector.login

stats = {
  :site_uri => config['site_uri'] ,
  :earliest => config['startDate'][0..6] ,
  :latest => Date.today.prev_month.end_of_month.iso8601[0..6] ,
}

last = options[:month]
first = options[:all_months] ? Date.iso8601(config['startDate']) : last
months = StatsExporter.month_list(first, last)

# get searchterms
month_list = {}
months.each do |month|
  index = month[:first].iso8601[0..6]
  logger.info("getting searchterms for #{index} ...")
  config['searchterms']['startTime'] = month[:first]
  config['searchterms']['stopTime'] = month[:last]
  result = connector.request_analysis(config['searchterms'])
  month_list[index] = {}
  month_list[index]['terms'] = result['analysisData'].map { |entry| [ entry[0].split("/").last.to_sym , 
    { :impressions => entry[1].to_i , 
      :visits => entry[2].to_i ,
      :page_duration_avg => entry[3].to_f ,
      :exit_rate => entry[4].to_f
    }
  ] }.to_h
end

stats[:months] = month_list

exporter_conf = {:stats => stats}
exporter_conf[:append_path] = json_out_file unless options[:replace]
exporter = StatsExporter.new(exporter_conf)

File.open(json_out_file, "wb") do |file|
  file.puts JSON.pretty_generate(exporter.to_json)
end
