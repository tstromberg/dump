#!/usr/bin/ruby
# Find domains that are words when combined with the TLD and standalone

wordfile = ARGV[0]


tlds = ['org', 'me', 'io', 'sh', 'so', 'at']


# these tld's have no working whois server: fm, vn

tld_regexp = tlds.join('|')
max_word = 9
min_word = 1
dictionary = []

# load up possible words in a dictionary
File.new(wordfile).readlines.each do |word|
  word.chomp!
  if word.length >= min_word and word.length <= max_word# and word =~ /#{tld_regexp}$/
    dictionary << word
  end
end

# check if any of the words also exist combined
dictionary.each do |word|
  tlds.each do |tld|
    printf "%s.%s\n", word, tld
  end
  
  #if word =~ /(.*?)(#{tld_regexp})$/ and dictionary.include?($1) then
  #  printf "%s.%s\n", $1, $2
  #end
end
