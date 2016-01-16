#!/usr/bin/env ruby

require 'optparse'
require 'yaml'
require 'twitter'
require 'colorize'

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

  # Color selector
  @@color_bracket = {:color => :light_white}
  @@color_counter = {:color => :light_yellow}
  @@color_at      = {:color => :light_green}
  @@color_nick    = {:color => :light_white}
  @@color_url     = {:color => :light_white , :mode => :underline}
  @@color_keyword = {:color => :light_red   , :mode => :underline}
  @@color_hashtag = {:color => :light_cyan}

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

  # Colorize output
  def colorize(text, keywords = [])
    # Retweets counter Highligh
    text.scan(/^\[[a-zA-Z0-9_]+\]/).each do |counter|
       ccounter = "#{counter[0].colorize(@@color_bracket)}#{counter[1..-2].colorize(@@color_counter)}#{counter[-1].colorize(@@color_bracket)}"
       text.gsub! counter, ccounter
    end
    # Twitter Username Highligh
    text.scan(/@[a-zA-Z0-9_]+/).each do |username|
       cusername = "#{username[0].colorize(@@color_at)}#{username[1..-1].colorize(@@color_nick)}"
       text.gsub! username, cusername
    end
    # URL Highligh
    text.scan(/https?:\/\/[\S]+/).each do |u|
       cu = u.colorize(@@color_url)
       text.gsub! u, cu
    end
    # Hashtag Highligh
    text.scan(/#[a-zA-Z0-9]+/).each do |hashtag|
       chashtag = hashtag.colorize(@@color_hashtag)
       text.gsub! hashtag, chashtag
    end
    # Keywords Highligh
    rgex = keywords.join("|")
    text.scan(/#{Regexp.escape(rgex)}/i).each do |k|
      ck = k.colorize(@@color_keyword)
      text.gsub! k, ck
    end
    return text
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
  def tweets(source: nil, top: nil, since: nil, links: false, color: false)
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

    # Keep only tweets including links if required
    if links
      my_tweet_list.each do |t|
        if t.urls.count == 0
          my_tweet_list.delete(t)
	end
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
	if color
          text = colorize(text)
        end
      else
        text = "<a href=\"#{t.uri}\">[#{t.retweet_count.to_s}]\t#{t.full_text}</a><br>"
      end
      output.push(text)
    end

    return output
  end

end

# Parse command line options
options = {:twitter_config => 'twitter.yml', :links => false}
OptionParser.new do |opts|
  opts.banner = "Usage: twitter_helper.rb [options]"

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

  opts.on("--color", "Colorize output") do |color|
    options[:color] = color
  end

  opts.on("-l", "--links", "Show only tweets with links") do |links|
    options[:links] = links
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
  output = helper.tweets(:source => options[:timeline], :top => options[:top], :links => options[:links], :color => options[:color])
  if output
    puts output
  else
    puts helper.error
  end
end

