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
  def colorize(text, keywords = nil)
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
    if keywords
      rgex = keywords.join("|")
      text.scan(/\b(#{rgex})\b/i).each do |k|
        sk = k.join
        ck = sk.colorize(@@color_keyword)
        text.gsub! sk, ck
      end
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

  # Filter tweets
  def tweet_filter(tweet_list: nil, top: nil, since:nil, links: false, keywords: nil)
    tweet_list.delete_if do |t|
      delete = false
      # Remove tweets that does not contain links
      if links && t.urls.count == 0
        delete = true
      end
      # Remove tweets that does not contain a keyword
      if keywords
        rgex = keywords.join("|")
	kcount = t.full_text.scan(/\b(#{rgex})\b/i).count
        if kcount == 0
          delete = true
        end
      end
      delete
    end

    # Sort tweets if required
    if top
      temp_array = tweet_list.sort_by {|t| t.retweet_count}
      tweet_list = temp_array.reverse.take(top)
    end
    return tweet_list
  end

  # Output formats
  def print(tweets: nil, color: false, html: false, keywords: nil)
    output = []
    tweets.each do |t|
      if html
        text = "<a href=\"#{t.uri}\">[#{t.retweet_count.to_s}]\t<@#{t.user.screen_name}> #{t.full_text}</a><br>"
      else
	text = "[#{t.retweet_count.to_s}]\t<@#{t.user.screen_name}> #{t.full_text}".delete("\n")
	if color
          text = colorize(text, keywords)
        end
      end
      output.push(text)
    end
    return output
  end

  # Return tweets
  def tweets(source: nil, top: nil, since: nil, links: false, color: false, keywords: nil)
    # Login if we have not logged yet
    if check_twitter or not login
      return nil
    end

    # Extract tweets from twitter
    if not source
      tweet_list = @twitter_client.home_timeline(:count => 200)
    else
      begin
        if source.start_with?("@")
          tweet_list = @twitter_client.user_timeline(source, :count => 200)
        else
          my_list = @twitter_client.list(source)
          tweet_list = @twitter_client.list_timeline(my_list, :count => 200)
        end
      rescue => e
        @error = "Source not found: #{e.message}"
        return nil
      end
    end

    # Filter tweets
    my_twitter_list = tweet_filter(:tweet_list => tweet_list, :top => top, :links => links, :keywords => keywords)

    # Translate to human readable
    return print(:tweets => my_twitter_list, :color => color, :keywords => keywords)
  end

  # Search tweets
  def search(top: nil, since:nil, links: false , color: false , keywords: nil )
    # Keywords are mandatory
    if keywords.nil? || keywords.count == 0
      return nil
    end 

    # Login if we have not logged yet
    if check_twitter or not login
      return nil
    end

    # Prepare search terms
    search_terms = "#{keywords.join(" ")} -filter:retweets"
    if links
      search_terms << " filter:links"
    end

    # Extract tweets from twitter
    tweet_list = []
    @twitter_client.search(search_terms, :result_type => "recent", :count => 100).each do |t|
      tweet_list.push(t)
    end

    # Filter results
    my_twitter_list = tweet_filter(:tweet_list => tweet_list, :top => top, :links => links)

    # Translate to human readable
    return print(:tweets => my_twitter_list, :color => color, :keywords => keywords)
  end

end

# Parse command line options
options = {:twitter_config => 'twitter.yml', :links => false, :keywords => nil, :search => nil}
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

  opts.on("-k x,y,z", "--keywords x,y,z", "Show only tweets containing those words") do |keywords|
    options[:keywords] = keywords.split(",")
  end

  opts.on("-s x,y,z", "--search x,y,z", "Search tweets containing those words") do |search|
    options[:search] = search.split(",")
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

# Request tweets or search
if options[:search]
  output = helper.search(:top => options[:top], :links => options[:links], :color => options[:color], :keywords => options[:search])
else
  output = helper.tweets(:source => options[:timeline], :top => options[:top], :links => options[:links], :color => options[:color], :keywords => options[:keywords])
end

# Print output
if output
  puts output
else
  puts helper.error
end

