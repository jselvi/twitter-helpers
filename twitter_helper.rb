#!/usr/bin/env ruby

require 'optparse'
require 'yaml'
require 'twitter'

class TwitterHelper

  # Error output variable
  @error = ''
  # Twitter instance variables
  @oauth_token     = nil 
  @oauth_secret    = nil 
  @consumer_key    = nil 
  @consumer_secret = nil
  @twitter_client  = nil
  # Output format
  @output_format = :text 

  # Constructor
  def initialize
  
  end

  # Print last error
  def error
    @error
  end

  # Set output format
  def html_output
    @output_format = :html
  end

  # Load YAML file
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

  # Check Twitter connection
  def check_twitter
    begin
      @twitter_client.user_timeline()
      return true
    rescue => e
      @error = "Twitter error: #{e.message}"
      return false
    end
  end

  # Twitter login
  def login
    @twitter_client = Twitter::REST::Client.new do |config|
      config.consumer_key        = @consumer_key
      config.consumer_secret     = @consumer_secret
      config.access_token        = @oauth_token
      config.access_token_secret = @oauth_secret
    end
    # check if login was sucessful
    check_twitter
  end

  # Return tweets
  def tweets(source: nil, top: nil, since: nil)
    # Login if we have not logged yet
    if check_twitter or not login
      return nil
    end

    # Extract tweets from twitter
    if not source
      my_tweet_list = @twitter_client.home_timeline(:count => 200)
    else
      begin
        if source.start_with?("@")
          my_tweet_list = @twitter_client.user_timeline(source, :count => 200)
        else
          my_list = @twitter_client.list(source)
          my_tweet_list = @twitter_client.list_timeline(my_list, :count => 200)
        end
      rescue => e
        @error = "Source not found: #{e.message}"
        return nil
      end
    end

    # Sort tweets if required
    if top
      temp_array = my_tweet_list.sort_by {|t| t.retweet_count}
      my_tweet_list = temp_array.reverse.take(top)
    end

    # Translate to human readable
    output = []
    my_tweet_list.each do |t|
      if @output_format != :html
        text = "[#{t.retweet_count.to_s}]\t#{t.full_text}"
      else
        text = "<a href=\"#{t.uri}\">[#{t.retweet_count.to_s}]\t#{t.full_text}</a><br>"
      end
      output.push(text)
    end

    return output
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

  opts.on("-t name", "--timeline name", String, "Select timeline (nil), list or @user") do |source|
    options[:timeline] = source
  end

  opts.on("--top num", Integer, "Top tweets (most retwitted)") do |top|
    options[:top] = top
  end

  opts.on("--html", "HTML output") do |html|
    options[:html] = html
  end

  opts.on("--stats", "Show statistics instead of tweets") do |stats|
    options[:stats] = stats
  end

end.parse!

# Instantiate helper class
helper = TwitterHelper.new

# Load twitter configuration
if not helper.load_yaml(options[:twitter_config])
  puts helper.error
  exit
end

# Set output if needed
if options[:html]
  helper.html_output
end

# Request tweets or statistics
if options[:stats]
  s = "pending to implement"
  puts s
else
  output = helper.tweets(:source => options[:timeline], :top => options[:top])
  if output
    puts output
  else
    puts helper.error
  end
end

