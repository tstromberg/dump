#!/usr/bin/env python
# script to backup tweets: timestamp and content.
#
# code based on http://code.activestate.com/recipes/576594/

import re
import sys
import time
from urllib2 import urlopen
from BeautifulSoup import BeautifulSoup

user = sys.argv[1]

for x in range(2**16):
  try:
    f = urlopen('http://twitter.com/%s?page=%s' % (user, x))
  except urllib2.HTTPError, e:
    sleep(20)
    f = urlopen('http://twitter.com/%s?page=%s' % (user, x))
    
  soup = BeautifulSoup(f.read())
  tweets = soup.findAll('span', {'class': 'entry-content'})
  if len(tweets) == 0:
    break

  timestamps = soup.findAll('span', {'class': 'published timestamp'})
  links = soup.findAll('a', {'class': 'entry-date'})

  for (index, tweet) in enumerate(tweets):
    tweet_text = re.sub('\<a.*?\>', '', tweet.renderContents())
    tweet_text = re.sub('\<\/a>', '', tweet_text)
    url = links[index]['href']
    date = timestamps[index]['data'].split("'")[1]
    print '"%s","%s","%s"' % (date.encode('UTF-8'), tweet_text, url.encode('UTF-8'))
  time.sleep(5)
