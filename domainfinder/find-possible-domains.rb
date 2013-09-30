#!/usr/bin/ruby
# Find domains that are words when combined with the TLD and standalone
#
# usage:
#
# cat /usr/share/dict/words | ./find-possible-domains.rb com net org
#
max_word = 12
min_word = 2

# An OK set of default TLD's
easy_tlds = [
  'am',
  #'at',   # Has very strict rate limiting
  'be',
  'biz',
  'bz',
  'cc',
  'cm',
  'co',
  'com',
  'de',
  #'es',   # No whois support
  'eu',
  #'fm',   # No whois support
  'gs',
  'in',
  'info',
  'io',
  'it',
  'la',
  #'ll',   # No whois support
  'ly',
  #'lo',   # No whois support
  'me',
  #'mn',   # No whois support
  'ms',
  'net',
  'nu',
  'org',
  'pl',
  're',
  'se',
  'sh',
  'so',
  'tk',
  'tl',
  'tv',
  'us',
  'vg',
  'ws',
  'xxx',
]

if ARGV.length > 0
  tlds = ARGV
else
  tlds = easy_tlds
end

tld_regexp = tlds.join('|')

dictionary = []

# load up possible words in a dictionary
$stdin.readlines.each do |word|
  word.chomp!
  if word =~ /\W/
    next
  end
  if word.length >= min_word and word.length <= max_word
    dictionary << word.downcase()
  end
end

# check if any of the words also exist combined
dictionary.each do |word|
  tlds.each do |tld|
    printf "%s.%s\n", word, tld
    if word.end_with?(tld)
      puts word.gsub(/(#{tld})$/, '.\1')
    end
  end
end
