#!/usr/bin/env ruby
require 'find'
require 'fileutils'
failures = []
if ARGV[0]
  Dir.chdir(ARGV[0])
end
count = 1

while count > 0
  count = 0
  Find.find(Dir.pwd) do |path|
  	if FileTest.file?(path)
  		if path =~ /(.*)\/(.*?)\.(zip|tar|tgz|rar|tar\.gz)/  
  		  if failures.include?(path)
  		    puts "Skipping previous failure: #{path}"
  		    next
  		  end
		  
  			dir = $1
  			basefile = $2
  			ext = $3.gsub(/\./, '_')
  			dest = dir + '/' + basefile + '_' + ext
  			cmd = nil
			
  			case ext
  				when 'zip'
  				  cmd = "unzip -o #{path}"
  				when 'tar_gz', 'tgz'
  				  cmd = "tar -zxvf #{path}"
  				when 'tar'
  				  cmd = "tar -xvf #{path}"
  				when 'rar'
  				  cmd = "unrar x #{path}"
  			end
			
  			if cmd
  			  size = File.lstat(path).size 
  			  sleep(1)
          if size != File.lstat(path).size
            puts "x #{path} is still being written to (#{size} vs #{File.lstat(path).size})) - skipping."
            next
          end
          
  			  count = count + 1
  			  puts "* Creating #{dest} for #{cmd}"
  			  FileUtils.mkdir_p(dest)
  			  Dir.chdir(dest)
  			  if system(cmd)
  			    puts "* Success! Removing #{path}"
            File.unlink(path)
          else
  			    puts "x Failure, not removing #{path}"
  			    failures << path
  			  end
  			end
  		end
  	end
  end
  
  if count > 0
    puts "Found #{count} files to de-archive"
  else
    puts "No files found do de-archive.. exiting."
  end
end

			