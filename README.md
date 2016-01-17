# twitter-helpers

This is a tool that can help when looking for information at twitter.
First of all, you need to copy the twitter.yml.example into a twitter.yml file and write your Twitter API credentials there.
You can also use several twitter credentials using the appropiate flag:

$ ./twitter_helper.rb --twitter-config other_twitter_config.yml

## Help

$ ./twitter_helper.rb -h
Usage: twitter_helper.rb [options]
    -h, --help                       Prints this help
        --twitter-config file        Twitter configuration file (YAML format)
    -t, --timeline name              Select timeline (nil), list or @user
        --top num                    Top tweets (most retwitted)
        --html                       HTML output
        --color                      Colorize output
    -l, --links                      Show only tweets with links
    -c, --cut num                    Cut the output lines to num characters
    -k, --keywords x,y,z             Show only tweets containing those words
    -s, --search x,y,z               Search tweets containing those words

## Usage examples

* Show tweets in my timeline:

$ ./twitter_helper.rb

* Show output colorized:

$ ./twitter_helper.rb --color

* Show tweets in my list "Readme":

$ ./twitter_helper.rb --timeline Readme --color

* Show tweets from a specific timeline:

$ ./twitter_helper.rb --timeline @mlw_re --color

* Show the most retwitted tweets:

$ ./twitter_helper.rb --top 10 --color

* Show only the most retwitted tweets that contain the keywords

$ ./twitter_helper.rb --keywords malware,intel,evil --top 10 --color

* Search (not only in your timeline) the terms and show the most retwitted tweets in HTML format:

$ ./twitter_helper.rb --search malware,intel,evil --top 10 --html

* Show the most retwitted tweets that contain the keyword but cut the text maximum at 100 chars:

$ ./twitter_helper.rb --color --keywords openssh --top 50 --cut 100


