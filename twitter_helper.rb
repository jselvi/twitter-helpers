#!/usr/bin/env ruby

require 'optparse'
require 'yaml'

class TwitterHelper

  # Error output variable
  @error = ''
  # Twitter instance variables
  @oauth_token     = nil 
  @oauth_secret    = nil 
  @consumer_key    = nil 
  @consumer_secret = nil 

  def initialize

  end

  def error
    @error
  end

  def load_yaml(config_file)
    parsed = begin
      YAML.load(File.open(config_file))
    rescue => e
      @error = "Could not open YAML: #{e.message}"
      return false 
    end
    @oauth_token     = parsed[:oauth_token]
    @oauth_secret    = parsed[:oauth_secret]
    @consumer_key    = parsed[:consumer_key]
    @consumer_secret = parsed[:consumer_secret]
    return true
  end

  def check_credentials
    true
  end

end

# Parse command line options
options = {:twitter_config => 'twitter.yml'}
OptionParser.new do |opts|
  opts.banner = "Usage: twitter_helper.rb [options]"

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end

  opts.on("-c file", "--twitter-config file", String, "Twitter configuration file (YAML format)") do |config|
    options[:twitter_config] = config
  end
end.parse!

# Instantiate helper class
helper = TwitterHelper.new

# Load twitter configuration
if not helper.load_yaml(options[:twitter_config])
  puts helper.error
  exit
end

# Check if credentials are correct
if helper.check_credentials
  puts "Credentials are correct"
else
  puts "Error accessing twitter"
end

