#!/usr/bin/env ruby
# dupelink 1.9
# (c) 2004 Indiana University - Thomas Stromberg <thomas+dupelink@stromberg.org>
#
# dupelink searches for duplicate files on a filesystem in an extremely efficient
# manner, and assuming the filesystem supports it, links each file together so that
# you save disk space. Because we use hard links, the files do not dissappear off the
# hard disk until the last link to it is removed. You can easily save gigs of disk space with
# this tool.
#
# Most filesystems do support hard links, the only ones I know of that do not is NTFS and FAT32.
#
# dupelink uses SQLite (an embedded SQL service) to record information and perform
# queries on the filesystem. As it is indexed for performance,  please  keep in mind
# that a database of 5 million files will easily take  over a gig of disk space. SQLite and
# SQLite-Ruby must be installed
#
# Please note that dupelink was inspired by freedups, which has many more options,
# and no pre-requisitites. It is extremely inefficient, however, and was taking over a week
# to execute on some of my filesystems. dupelink in most cases will be 10-50x faster depending
# on how many links there are already on the filesystem.
#
# $HeadURL: http://revision.chem.indiana.edu/repos/scripts/unix/dupelink.rb $
# $Id: dupelink.rb 560 2005-02-12 12:41:48Z tstrombe $
#######################################################################
require 'find'
require 'digest/md5'
require 'sqlite3'

$inodeHash = Hash.new
$Time = Time.new

# Location of md5 or md5sum. Please note that md5sum performs better than
# BSD md5, OpenSSL md5, md5deep on my Pentium III Linux box.
if File.exists?('/usr/bin/md5sum')
  $MD5="/usr/bin/md5sum"
else
  $MD5="/usr/bin/md5"
end

$IGNORE_PERMISSIONS=1

# ignore files under this size. Speeds up searches a lot, and if you
# are using temporary tables, it saves you RAM.
$MINSIZE=1024

# Should tables be temporary (in memory) or on disk? temporary is faster.
# Comment this out if you find yourself running out of RAM.
$TEMP="TEMPORARY";

# if your tables are temporary, you may want to set much lower memory limits:
$MAXINODES=25000000
$MAXFILES=50000000

# How much memory should be dedicated to caching. This is generally the size
# in KB
$CACHE_SIZE="512000"

# We should run results every X number of possibile file matches
$MATCH_EVERY=5000

# Post scanning status every X number of files
$SCANSTATUS_EVERY=20000

# exceptions
$EXCEPTIONS="\.svn"

## DO NOT TOUCH UNDER HERE ################################################


class ProgressBar
  def initialize(start, max, name)
    @value = 0
    @max = max
    @name = name
    @time = $Time
    @length = 3
    @autoupdate = 60
    @lastupdate = 0
    display
  end

  def dputs(string)
    $Time = Time.new
    #puts $Time.strftime("%H:%M") + " " + string
    # we used to put the time, now -- why bother?
    puts $Time.strftime("%H:%M") + " " + string
  end

  def update(value)
    @value = value
  end

  def name(name)
    @name = name
  end

  def autoupdate=(value)
    @autoupdate = value
  end

  def updateText(value, valueText)
    @value = value
    @valueText = valueText
    $Time = Time.new
    @elapsed = ($Time.to_i - @lastupdate)

    if ((@elapsed > @autoupdate) || (value == @max))
      display
    end
    x=0        # damned SQLite bug!
  end

  def max(value)
    @max = max
  end

  def length(value)
    @length = value
  end

  def display
    if (@max == 0)
      showMax = "?"
    else
      showMax = @max
    end

    # if the value is 0 or less, don't bother to print up a bar.
    if (@value < 1)
      return
    end

    percentage = (@value.to_f / @max.to_f) * 100
    bardiv = percentage.divmod((100/@length))

    fullbars = bardiv[0]
    minibars = bardiv[1] / (50/@length)
    #dputs "p=#{percentage} f=#{fullbars} m=#{minibars}"
    meter = "=" * fullbars + "-" * minibars
    meter = meter.ljust(@length)

    if (@valueText)
      dputs "[#{meter}] (#{percentage.to_i}%) #{@name}: #{@valueText}"
    else
      dputs "[#{meter}] (#{percentage.to_i}%) #{@name}"
    end
    $Time = Time.new
    @lastupdate = $Time.to_i
  end
end



class DupeLink
  def dputs(string)
    $Time = Time.new
    #puts $Time.strftime("%d%b %H:%M") + "  " + string
    # we used to put the time, now -- why bother?
    puts $Time.strftime("%H:%M") + " " + string
  end

  def debug(string)
    if ENV['DEBUG']
      $Time = Time.new
      puts $Time.strftime("%d%b %H:%M") + "  " + string
    end
  end

  def initialize
    $DBFile="/var/tmp/dupelink-" + $Time.to_i.to_s + ".db"
    @totalFiles = 0
    @totalInodes = 0
    @totalSpaceSaved = 0
    @filesLinked = 0
    @totalFilesChecked = 0

    # for now, no resumes.
    if File.exists?($DBFile)
      File.unlink($DBFile)
      sleep(2)
    end

    if (! File.exists?($DBFile))
      dputs "[ % ] Creating database in #{$DBFile}"
      @db = SQLite3::Database.new($DBFile)

      # optimizations
      @db.execute("PRAGMA default_cache_size=#{$CACHE_SIZE};");
      @db.execute("PRAGMA default_synchronous=OFF;");
      @db.execute("PRAGMA count_changes=OFF;");

      #dputs "[ % ] Creating new tables for database"


      @db.execute <<SQL
CREATE #{$TEMP} TABLE inode (
    inode INTEGER PRIMARY KEY,
    links INT NOT NULL,
    perm INT NOT NULL,
    uid INT NOT NULL,
    gid INT NOT NULL,
    size INT NOT NULL,
    md5 VARCHAR(32)
);
SQL


      @db.execute <<SQL
CREATE #{$TEMP} TABLE file (
    fid INTEGER PRIMARY KEY,
    finode INT NOT NULL,
    name VARCHAR(256)
);
SQL

      @db.execute("CREATE INDEX idxinode ON inode(inode);");
      @db.execute("CREATE INDEX idxfino ON file(finode);");
      @db.execute("CREATE INDEX idxffid ON file(fid);");
    else
      @db = SQLite3::Database.new( file, 0 )
    end
  end


  def search(dir, maxinodes, maxfiles)
    dputs "[.s.] Finding files within #{dir}.."
    @db.transaction

    dirFiles = 0
    searchFiles = 0
    searchInodes = 0


    Find.find(dir) { |path|
      if path =~ /#{$EXCEPTIONS}/
        next
      end
      # Don't bother linking files underneath a certain size
      begin
        if (File.lstat(path).ftype == "file") && (File.lstat(path).size > $MINSIZE)
          inode=File.lstat(path).ino

          if (! $inodeHash[inode])
            @db.execute("INSERT INTO inode (inode, links, perm, uid, gid, size) VALUES
                          (#{inode}, #{File.lstat(path).nlink}, #{File.lstat(path).mode}, #{File.lstat(path).uid}, #{File.lstat(path).gid}, #{File.lstat(path).size});");
            $inodeHash[inode]=1
            searchInodes = searchInodes + 1
          end

          tpath = path.gsub(/\"/, "\"\"");
          @db.execute("INSERT INTO file (name, finode) VALUES (\"#{tpath}\", #{inode});");
          searchFiles = searchFiles + 1
          dirFiles = dirFiles + 1

          # we actually use dirfiles, since we get a status update when a new one starts anyways.
          if (dirFiles > 1) && ((dirFiles % $SCANSTATUS_EVERY) == 1)
            dputs "[ s ] Status: #{searchFiles} files, #{searchInodes} inodes, #{path}"
            # flush the database from memory to disk
            @db.commit
            @db.transaction
          end

          if @totalInodes > maxinodes
            dputs "[!s!] Maximum inodes (#{maxinodes}) reached.). Processing.."
            @db.commit
            return
          end

          if @totalFiles > maxfiles
            dputs "[!s!] Maximum files (#{maxfiles}) reached.). Processing.."
            @db.commit
            return searchFiles
          end
        end
      rescue
        dputs "Could not get details on #{path}"
      end
    }

    dputs "[ s ] Scan Complete. #{searchFiles} files (#{searchInodes} inodes) were found."
    @totalFiles = @totalFiles + searchFiles
    @totalInodes = @totalInodes + searchInodes

    # if they have a whole lot of directories specified at the command line, give em the aggregate.
    if (@totalFiles != searchFiles)
      dputs "[ s ] The aggregated total is #{@totalFiles} files and #{@totalInodes} inodes."
    end

    # commit the database
    begin
      @db.commit
    rescue
      dputs "[ ! ] error committing db. Could just be out of order."
    end
    return searchFiles
  end

  def locateCandidates()
    dputs "[.C.] Searching database for candidates to checksum..."
    possibleSavings = 0
    @totalCandidates = 0
    @totalCandidateSpace = 0
    @queueCandidates = 0
    @queueCandidateSpace = 0
    $Time = Time.new
    time = $Time.to_i

    lsize  = 0
    luid  = 0
    lgid = 0
    lperm  = 0
    linode  = 0

    dbinode=0
    dbsize=1
    dbperm=2
    dbuid=3
    dbgid=4

    @db.transaction
    @db.execute( "SELECT inode, size, perm, uid, gid FROM inode GROUP BY inode ORDER BY size DESC" ) do |row|
      # obviously not a candidate. Lets see if we should go ahead and run our results before we commit this file in.
      if row[dbsize] == lsize:
        if $IGNORE_PERMISSIONS == 1 or (row[dbuid] == luid && row[dbgid] == lgid && row[dbperm] == lperm):
          @db.execute("UPDATE inode SET md5=\'1\' WHERE inode=#{row[dbinode]}")
          @db.execute("UPDATE inode SET md5=\'1\' WHERE inode=#{linode} ")
          @queueCandidates = @queueCandidates + 2
          @queueCandidateSpace = @queueCandidateSpace + (row[dbsize].to_i * 2)
        end
      end

      if @queueCandidates > $MATCH_EVERY
        posSize = sizeUnit(@queueCandidateSpace)
        dputs "[ c ] #{posSize} worth of candidates found. Now analyzing file content for matches.."
        # flush the database from memory to disk
        @db.commit

        # go go go!
        checkCandidates()
        saved = linkFiles()

        cleanDatabase()
        @db.transaction
        @queueCandidates = 0
        @queueCandidateSpace = 0
      end

      lsize = row[dbsize]
      luid = row[dbuid]
      lgid = row[dbgid]
      lperm = row[dbperm]
      linode = row[dbinode]
    end
    @db.commit

    # one last shot!
    if @queueCandidates > 1
      posSize = sizeUnit(@queueCandidateSpace)
      dputs "[ c ] #{posSize} of remaining candidates found. Now analyzing file content for matches.."

      checkCandidates()
      linkFiles()
    end

    @totalCandidateSpace = @totalCandidateSpace + @queueCandidateSpace
    @totalCandidates = @totalCandidates + @queueCandidates
    return @totalCandidateSpace
  end

  def checkCandidates
    @db.transaction
    prog = ProgressBar.new(0, @queueCandidateSpace, "Checksumming");
    filesChecked = 0
    spaceChecked = 0

    #dputs "[ x ] Checksumming the nominees..."

    # cheap hack to label the SQL ordering since sqlite no longer
    # hands back a hash. It's actually faster, anyways.
    dbinode = 0
    dbname = 1
    dbsize = 2

    # increase the automatic updates
    prog.autoupdate=45

    # this routine seems to leak ram like a sunufabitch.

    @db.execute( "SELECT inode, name, size FROM inode, file WHERE file.finode == inode.inode AND inode.md5=\'1\' GROUP BY inode ORDER BY size DESC" ) do |row|
      file = row[dbname]
      if File.readable?(file)
        # if it's larger than 2.5M, lets just execute md5sum. This was
        # determined systematically for performance reasons.
        # see the md5-sweetspot utility.
        digest = nil
        if row[dbsize].to_i > 2482206
          digest = `#{$MD5} "#{file}"`.split(' ')[0]
          if ! digest or digest.length != 32
            dputs "[!x!] #{$MD5} on #{file} return invalid: #{digest} - using internal"
          end
	end
        if ! digest or digest.length != 32
          digest = Digest::MD5.hexdigest(File.new(file).read)
          if ! digest or digest.length != 32
            dputs "failed to get md5 hash for #{file}, skipping"
            next
          end
        end

        @db.execute("UPDATE inode SET md5=\'#{digest}\' WHERE inode=#{row[dbinode]}")
        spaceChecked = spaceChecked + row[dbsize].to_i
        filesChecked = filesChecked + 1
        if ((filesChecked % 150) == 0)
          prog.updateText(spaceChecked, "#{file} (#{row[dbsize]} bytes)");
          # flush the database from memory to disk
          @db.commit
          @db.transaction
        end
      else
        dputs "[!x!] #{file} is not readable!"
      end
    end

    @db.commit
    @totalFilesChecked = @totalFilesChecked + filesChecked
  end

  def linkFiles
    lastNewMD5='x'
    lastNewFile='x'
    lastNewInode=0
    filesLinked=0

    # cheap hack to label the SQL ordering since sqlite no longer
    # hands back a hash!
    dbname = 0
    dbsize = 1
    dbmd5 = 2
    dbinode = 3

    spaceSaved = 0
    lastInode = 0

    # why sort names in ascending instead of descending? It's because of the way our backup system works. If we accidently run
    # this script while backups are running, we want to link everything to the oldest file, not the newest. Even if it looks
    # weird when reading the output!

    @db.execute( "SELECT name, size, md5, inode, links FROM inode, file WHERE file.finode == inode.inode AND inode.md5 != \'\' ORDER BY size DESC, links DESC, inode DESC, name ASC" ) do |row|
      filename = row[dbname]

      if (row[dbinode] != lastNewInode) && (row[dbmd5] == lastNewMD5) && (lastNewMD5.length == 32)
        begin
          File.unlink(filename)
          File.link(lastNewFile, filename)
          filesLinked = filesLinked + 1

          # only count if it's now a new inode. Don't bother the user
          # with printing useless linking information if it saves them no space.
          if row[dbinode] != lastInode
            spaceSaved = spaceSaved + row[dbsize].to_i
            dputs "[ L ] #{filename} -> #{lastNewFile} (#{row[dbsize]})"
          end
          lastInode = row[dbinode]
        rescue
          dputs "[!L!] Could not link #{filename} to #{lastNewFile}"
        end
      else
        # only set the lastNew if it's a new md5 hash.
        lastNewMD5 = row[dbmd5].dup
        lastNewFile = filename.dup
        lastNewInode = row[dbinode]
      end
    end

    @totalSpaceSaved = @totalSpaceSaved + spaceSaved
    @filesLinked = @filesLinked + filesLinked

    if spaceSaved > 1
      saved = sizeUnit(spaceSaved)

      if spaceSaved != @totalSpaceSaved
        saved = saved + " (session total: " + sizeUnit(@totalSpaceSaved) + ")"
      end

      dputs "[:L:] Linked together #{filesLinked} files, reclaiming #{saved} of space."
    end

    return spaceSaved
  end

  def cleanDatabase
    # This will clean all candidates, regardless of success, from the queue
    @db.execute("DELETE from inode WHERE inode.md5 != \'\'")
    @db.execute("VACUUM")
  end

  def close
    @db.close
    File.unlink($DBFile);
  end


  def totalSpaceSaved
    return @totalSpaceSaved
  end

  def filesLinked
    return @filesLinked
  end

  def totalFilesChecked
    return @totalFilesChecked
  end

  def totalFiles
    return @totalFiles
  end

  def totalInodes
    return @totalInodes
  end

  def sizeUnit(bytes)
    # change to case
    if bytes > (1024 * 1024 * 1024)
      return sprintf("%.1fGB", bytes / 1024 / 1024 / 1024)
    end

    if bytes > (1024 * 1024)
      return sprintf("%.1fMB", bytes / 1024 / 1024)
    end

    if bytes > 1024
      return sprintf("%.0fkb", bytes / 1024)
    else
      return sprintf("%ib", bytes)
    end
  end
end

$stdout.sync = true

timeStart = Time.new

dupe = DupeLink.new
counter = 0

ARGV.each { |dir|
  counter = counter + 1

  if ((ARGV.length > 1) && (counter < ARGV.length))
    inodes = $MAXINODES - 75000
    files = $MAXFILES - 125000
  else
    inodes = $MAXINODES
    files = $MAXFILES
  end

  dupe.search(dir, inodes, files)
  puts ""
}

dupe.locateCandidates
dupe.close

timeEnd = Time.new

min = sprintf("%.1f", (timeEnd - timeStart) / 60)
saved = dupe.sizeUnit(dupe.totalSpaceSaved)

puts ""
dupe.dputs "[ @ ] dupelink run completed in #{min} minutes!"
dupe.dputs "[ @ ] Total files scanned: #{dupe.totalFiles} (#{dupe.totalInodes} inodes)"
dupe.dputs "[ @ ] Total inodes analyzed: #{dupe.totalFilesChecked}"
dupe.dputs "[ @ ] Total files linked: #{dupe.filesLinked}"
dupe.dputs "[ @ ] Total Space Saved: #{saved}"
