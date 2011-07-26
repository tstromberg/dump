#!/usr/bin/env python
#
# Copy random decent-quality photos from the hard drive into a directory suitable for 
# the Mac OS X Pictures screensaver.

import commands
import os
import os.path
import random
import re
import shutil
import stat
import sys

LOCATE_CMD = '(locate -i .jpg; locate -i .nef; locate -i .tif)'
EXCLUDE = sys.argv[1]
INCLUDE = '\.jpg$|\.nef$|\.png$|\.tif$|\.crw$'
NUM_FILES = 100
MIN_SIZE = 100000
DEST_DIR = sys.argv[2]

def ClearDirectory(dir):
  try:
    for file in os.listdir(dir):
      full_path = os.path.join(dir, file)
      if os.path.isfile(full_path):
        os.remove(full_path)
  except:
    print "Could not clear %s" % dir

def CopyImages(image_paths, dest_dir):
  if not os.path.exists(dest_dir):
    os.makedirs(dest_dir)
  for path in image_paths:
    if os.path.isfile(path):
      print path
      shutil.copy(path, dest_dir)

def FindImages(command, exclude, include, min_size, num_files):
  chosen = []
  files = commands.getoutput(command).split('\n')
  print "%s candidates found" % len(files)
  exclude_re = re.compile(exclude, re.IGNORECASE)
  include_re = re.compile(include, re.IGNORECASE)

  while len(chosen) < num_files:
    file = random.choice(files)
    if (include_re.search(file) and not exclude_re.search(file)
        and os.path.exists(file) and  os.path.getsize(file) > min_size):
      chosen.append(file)
  return chosen
	
if __name__ == '__main__':
  images = FindImages(LOCATE_CMD, EXCLUDE, INCLUDE, MIN_SIZE, NUM_FILES)
  print "Files chosen: %s" % images
  ClearDirectory(DEST_DIR)
  CopyImages(images, DEST_DIR)
