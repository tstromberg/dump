#!/usr/bin/python2.7
# Outputs HTML unordered list of donors sorted by contribution total.
import collections
import csv
import sys

d = collections.defaultdict(list)
MY_NAME = 'Thomas R Stromberg'

for row in csv.DictReader(open(sys.argv[1])):
  amount = float(row['Gift Amount'].replace('$', ''))
  name = '%s %s (%s)' % (row['First Name'], row['Last Name'], row['Email'])
  d[name].append(amount)

for donor, amount in sorted(d.iteritems(), key=lambda x: sum(x[1]), reverse=True):
  if MY_NAME not in donor:
    print '"%s",%s' % (donor,sum(amount))
