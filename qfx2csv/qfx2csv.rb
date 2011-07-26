#!/usr/bin/ruby
# qfx2csv 1.0 (2006-09-29) by Thomas Stromberg <thomas%stromberg.org>
# 
# This script will attempt to parse a QFX (Quicken File Exchange) file 
# and output a CSV file for use in spreadsheet software. It has been tested 
# against Quicken 2004 & 2007 formatted files for Windows and Mac OS X,
# as exported by Wachovia.
# 
# This script requires Ruby (http://www.ruby-lang.org/) to be installed. Ruby
# comes with Mac OS X and most Linux distributions, but other users may need
# to insall it. Usage of this script is very simple.
# 
# ruby qfx2csv.rb /path/to/filename.qfx > filename.csv 
#
# 
# ########################### (MIT LICENSE) ####################################
# Copyright (c) 2006 Thomas Stromberg
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of 
# this software and associated documentation files (the "Software"), to deal in 
# the Software without restriction, including without limitation the rights to 
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do 
# so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all 
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
# SOFTWARE.

def parseOFXFile(filename)
  raw_data = parseOFXData(File.open(filename).readlines)
  puts formatCSV(raw_data)
end
  
def parseOFXData(data)
  parsed = Array.new
  transaction = nil
  
  data.each do |line|
    # ignore lines that do not look like OFX tags.
    if line !~ /\<(\w+)\>(.*)/
      next
    end

    tag = $1
    data = $2

    # this tag specifies the beginning of a transaction record
    if tag == "STMTTRN"
      if transaction
        parsed << transaction
      end
      transaction = Hash.new
    else
      if transaction
        transaction[tag] = data
      end
    end
    
    # The date a transaction was posted is formatted in an odd way, make it sane
    if tag == "DTPOSTED"
      if data =~ /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/
        transaction['date'] = sprintf("%s-%s-%s %s:%s:%s", $1, $2, $3, $4, $5, $6)
      end
    end
    
    # Same with the transaction amount.
    if tag == "TRNAMT"
      transaction['amount'] = sprintf("%2.2f", data.to_f)
    end
  end
  
  parsed << transaction
end

def formatCSV(data)
  csv = Array.new
  data.each do |tr|
    csv << sprintf("%s,\"%s\",%s,%s,\"%s\",\"%s\"", tr['FITID'], tr['date'], tr['TRNTYPE'], 
                                                 tr['amount'], tr['NAME'], (tr['CHECKNUM'] || tr['MEMO']))    
  end
  return csv
end

if ARGV[0]
  parseOFXFile(ARGV[0])
else
  puts "qfx2csv 1.0 - usage:\n\n"
  puts "  ruby qfx2csv.rb /path/to/file.qfx > filename.csv"
end

  