#!/usr/bin/env python
import sys
import logging
import os.path
import datetime
import cPickle as pickle
import threading

MAX_REQUEST_DELTA_SECONDS = 120
SAVE_EVERY_SECONDS = 300
QUOTA_SECONDS = 7200
LOG_FILE = "/tmp/squidtimer.log"
STATE_FILE = "/var/tmp/squidtimer.state"
EXCEPTIONS = ('channel13.facebook.com','spreadsheets.google.com', '/api/', 'xmlrpc')

def logmsg(string):
  f = open(LOG_FILE, "a")
  f.write("%s: %s\n" % (datetime.datetime.now(), string))
  f.close()

class SaveThread(threading.Thread):
  def __init__(self, file, today, state):
    self.file = file
    self.today = today
    self.state = state
    threading.Thread.__init__(self)
    
  def run(self):
    logmsg("Saving state: %s" % self.state)
    pfile = open(self.file, 'wb')
    pickle.dump((self.today, self.state), pfile)
    logmsg("State saved to %s" % self.file)

class SquidTimer(object):

  def __init__(self):
    self.reset_quota()
    self.load_state()
    self.save_state()
    logmsg("SquidTimer started!")
  
  def reset_quota(self):
    self.today = datetime.datetime.now().date()
    self.state = { 'last': {}, 'duration': {} }
    self.last_save = None
  
  def load_state(self):
    if os.path.exists(STATE_FILE):
      logmsg("Loading state file: %s" % STATE_FILE)
      pfile = open(STATE_FILE, 'rb')
      try:
        (self.today, self.state) = pickle.load(pfile)
        logmsg("Loaded from %s: %s" % (self.today, self.state))
      except:
        self.reset_quota()
        logmsg("Failed to load pickle from %s, reset state." % (STATE_FILE))
      
  def save_state(self):
    save_thread = SaveThread(STATE_FILE, self.today, self.state)
    save_thread.start()
    self.last_save = datetime.datetime.now()
  
  def process_request(self, request):
    # http://www.flickr.com/services/xmlrpc/ 10.0.0.132/sallad-dell - POST -
    (url, src, ident, method) = request.split()[0:4]
    if method != 'GET':
      return url
    
    for substring in EXCEPTIONS:
      if substring in url:
        return url

    new_url = url
    now = datetime.datetime.now()
    if now.date() != self.today:
      self.reset_quota()
      
    if (now - self.last_save).seconds >= SAVE_EVERY_SECONDS:
      self.save_state()
      
    if src in self.state['last']:
      src_delta = (now - self.state['last'][src]).seconds
      if src_delta < MAX_REQUEST_DELTA_SECONDS:
        self.state['duration'][src] += src_delta
      if self.state['duration'][src] >= QUOTA_SECONDS:
        logmsg("%s is out of quota." % src)
        new_url = "http://localhost/out_of_time"
    else:
      self.state['duration'][src] = 0
    self.state['last'][src] = now
    logmsg("%s [%s]: %s -> %s" % (src, self.state['duration'][src], url, new_url))
    return new_url

if __name__ == '__main__':
  st = SquidTimer()
  while True:
    line = sys.stdin.readline().strip()
    if line:
      answer = st.process_request(line)
      if answer:
        sys.stdout.write(answer + "\n")
        sys.stdout.flush()
