#!/usr/bin/env ruby
# pass me some input and I will attempt to extract normal looking words out of it.

min_occurances = (ARGV[0] || 1).to_i
min_word = 3
max_word = 24

used={}
$stdin.each do |line|
  # clean out any HTML on the line.. kind of wasteful.
  line.gsub!(/\<.*?\>/, '')
  
  # split the line into words seperated by normal english word boundaries
  words = line.split(/[,\.\b\s\/\;]+/) 

  # go through each word and check constraints
  words.each do |word|
    word.downcase!
    next if used[word] and used[word] >= min_occurances
    next if word !~ /^[a-z]+$/ 
    
    if word.length >= min_word and word.length <= max_word then
      if not used[word] then
        used[word] = 1
      else
        used[word] = used[word] + 1
      end
      
      if used[word] >= min_occurances then
        puts word
      end
    end
  end
end


