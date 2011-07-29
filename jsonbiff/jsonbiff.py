# Copyright 2011 Google Inc. All Rights Reserved.

"""Simple X Window to notify when a remote JSON value has changed.

Syntax:

  ./jsonbiff.py url://to/json <value to extract> <seconds between polls>

For example:


"""

__author__ = 'tstromberg@google.com (Thomas Stromberg)'

import logging
import json
import Queue
import os
import urllib2
import sys
import time
import threading
import traceback

# Wildcard imports makes baby jesus cry.
from Tkinter import *

THREAD_UNSAFE_TK = False
global_message_queue = Queue.Queue()
global_last_message = None
CLOSING_TIME = False

DEFAULT_TEXT_WIDTH = 12

COLOR_EMPTY_BACKGROUND = 'lightgrey'
COLOR_EMPTY_FOREGROUND = 'darkgrey'
COLOR_FOREGROUND = 'black'
COLOR_BACKGROUND0 = 'snow'
COLOR_BACKGROUND1 = 'misty rose'


def window_close_handler():
  global CLOSING_TIME
  # TODO(tstromberg): Force threads to exit, don't just sit back and wait.
  print 'Closing, waiting for threads to exit.'
  CLOSING_TIME = True
  sys.exit(1)


def add_msg(message, root_window=None, backup_notifier=None, **unused_kwargs):
  """Add a message to the global queue for output."""
  global global_last_message
  global THREAD_UNSAFE_TK

  logging.info('add_msg: %s -> %s' % (message, root_window))

  if message != global_last_message:
    global_message_queue.put(message)

  if CLOSING_TIME:
    sys.exit(1)
    return

  if root_window:
    try:
      root_window.event_generate('<<msg>>', when='tail')
      logging.debug("Generated event")
      global_last_message = message
    # Tk thread-safety workaround #1
    except TclError:
      # If we aren't thread safe, we already assume this won't work.
      if not THREAD_UNSAFE_TK:
        print 'First TCL Error:'
        traceback.print_exc()
      try:
        backup_notifier(-1)
        THREAD_UNSAFE_TK = 1
      except:
        print 'Backup notifier failure:'
        traceback.print_exc()


class JsonBiffGui(object):

  def __init__(self, url, var, poll_seconds):
    self.url = url
    self.var = var
    self.poll_seconds = poll_seconds

  def run(self):
    self.root = Tk()
    app = MainWindow(self.root, self.url, self.var, self.poll_seconds)
    app.draw_window()
    self.root.bind('<<msg>>', app.message_handler)
    self.root.mainloop()


class MainWindow(Frame):
  def __init__(self, root, url, var, poll_seconds):
    Frame.__init__(self)
    self.root = root
    self.url = url
    self.var = var
    self.worker = None
    self.last_msg = None
    self.poll_seconds = poll_seconds
    self.root.protocol('WM_DELETE_WINDOW', window_close_handler)

  def draw_window(self):
    """Draws the user interface."""
    self.root.title('jsonbiff')
    #self.status = StringVar()
    self.outer_frame = Frame(self.root)
    self.outer_frame.grid(row=0, padx=6, pady=6)

    self.text = Text(self.outer_frame, height=1, width=10)
    self.text.tag_config('empty', background=COLOR_EMPTY_BACKGROUND,
                    foreground=COLOR_EMPTY_FOREGROUND)
    self.text.tag_config('color0', background=COLOR_BACKGROUND0,
                    foreground=COLOR_FOREGROUND)
    self.text.tag_config('color1', background=COLOR_BACKGROUND1,
                    foreground=COLOR_FOREGROUND)
#    status = Label(outer_frame, text='...', textvariable=self.status)
#    status.grid(row=15, sticky=W, column=0)
    self.update_status('Starting.', notify=False)
    self.start_job()

  def message_handler(self, unused_event):
    """Pinged when there is a new message in our queue to handle."""
    logging.debug('message_handler called. Queue: %s' %
                  global_message_queue.qsize())
    while global_message_queue.qsize():
      m = global_message_queue.get()
      self.update_status(m)

  def update_status(self, msg, notify=True):
    tag = None
    if not isinstance(msg, list):
      if notify:
        self.send_notification(msg)
      msg = [msg]
    elif isinstance(self.last_msg, list):
      if msg and notify:
        new = set(msg).difference(set(self.last_msg))
        if new:
          self.send_notification('New Items: \n\n' + '\n\n'.join(new))

    if msg:
      self.text.configure(height=len(msg))
      max_user_len = max([len(x) for x in msg])
      self.text.configure(width=max([DEFAULT_TEXT_WIDTH, max_user_len]))
    else:
      self.text.configure(width=DEFAULT_TEXT_WIDTH, height=1,)
      tag = 'empty'
      msg = ['(empty)']

    self.text.delete(1.0, END)
    for i, item in enumerate(msg):
      if not tag:
        tag = 'color%s' % (i % 2)
      logging.debug('Inserting text [%s]: %s tag=%s' % (i, item, tag))
      self.text.insert(END, '%s\n' % item, tag)
      tag = None
    self.text.pack()
    self.last_msg = msg

  def send_notification(self, msg):
    """gnome only?"""
    os.system('notify-send jsonbiff \"%s\"' % msg)

  def start_job(self):
    logging.info('starting job?')
    self.worker = WorkerThread(self.url, self.var, self.poll_seconds,
                               root_window=self.root,
                               backup_notifier=self.message_handler)
    self.worker.start()


class WorkerThread(threading.Thread):

  def __init__(self, url, var, poll_seconds, root_window=None,
               backup_notifier=None):
    self.json_biff = JsonFetcher(url, var)
    self.poll_seconds = poll_seconds
    self.root_window = root_window
    self.backup_notifier = backup_notifier
    threading.Thread.__init__(self)

  def run(self):
    while True:
      logging.debug("Run loop")
      value = self.json_biff.get_value()
      logging.debug("Value: %s" % value)
      add_msg(value, root_window=self.root_window,
              backup_notifier=self.backup_notifier)
      time.sleep(self.poll_seconds)

class JsonFetcher(object):

  def __init__(self, url, var):
    self.url = url
    self.var = var

  def get_value(self):
    return self.evaluate(self.fetch())

  def fetch(self):
    return urllib2.urlopen(self.url).read()

  def evaluate(self, data):
    json_data = json.loads(data)
    logging.debug('data: %s' % json_data)
    if self.var in json_data:
      return json_data.get(self.var)
    else:
      logging.warning('%s not in %s' % (self.var, json_data))
      return None


if __name__ == '__main__':

  if len(sys.argv) != 4:
    print 'jsonbiff'
    print '--------'
    print './jsonbiff.py <url> <var> <seconds between polls>'
    sys.exit(1)

  url, expression, poll_seconds = sys.argv[1:]
  if not os.getenv('DISPLAY', None):
    logging.critical('No DISPLAY variable set.')
    sys.exit(2)

  ui = JsonBiffGui(url, expression, poll_seconds=int(poll_seconds))
  ui.run()
