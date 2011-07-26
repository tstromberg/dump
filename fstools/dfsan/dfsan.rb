#!/usr/bin/env ruby
# dfsan 1.2
#
# Shows how much disk space is available from the SAN, mostly 
# by parsing syminq and vxprint
#
# $Id: dfsan.rb 545 2006-03-01 15:56:05Z thomas $

$SYMINQ="/usr/symcli/bin/syminq"
$VXPRINT="/usr/sbin/vxprint"
$VXDISK="/usr/sbin/vxdisk"

class StorageInfo
	attr		:diskInfo
	attr		:vxInfo
	def initialize
		@diskInfo = Hash.new
		@vxInfo = Hash.new
		getSyminq()
		uniqueDisks()
		getVxDiskList()
		getVxPrint()
	end
	
	def getSyminq
		`#$SYMINQ`.each_line do |line|
		    #               /dev/rdsk/c2t52d41s2    M(2) EMC       SYMMETRIX        5568 251E3000  23569920
			#				/dev/rdsk/c2t72d255s2     GK     EMC       SYMMETRIX    5670 400001C000       2880
			if line =~ /^\/.*?(\w+) +(.*?) +(\w+)  +(\w[\w \*]+) +(\d+) +(\w+) +(\w+)$/
				device = $1		
				debug "adding device #{device}: #{line}"
				if ! @diskInfo[device]
					@diskInfo[device] = Hash.new
				end

				@diskInfo[device]['type'] = $2
				@diskInfo[device]['vendor'] = $3
				@diskInfo[device]['version'] = $5
				@diskInfo[device]['serial'] = $6
				@diskInfo[device]['capacity'] = $7.to_i
				@diskInfo[device]['brand'] = $4.gsub(/ +$/, '')
				
				if @diskInfo[device]['type'] =~ /GK/ 
					@diskInfo[device]['unusable'] = 1
				end
			else
				debug "NO MATCH: #{line}"
			end
		end
		if @diskInfo.keys.length == 0
			puts "No disks found my syminq. You may need to run dfsan as root or check your PATH."
			exit(9)
		end
	end
	
	def findUniqueDisk(dev)
		debug "find dupe of #{dev}"
		if @diskInfo[dev] && @diskInfo[dev]['dup']
			debug "the real id for #{dev} is #{@diskInfo[dev]['dup']}"
			return @diskInfo[dev]['dup']
		else
			return dev
		end
	end

	# These disks do not show up in vxprint with a diskname!
	def getVxDiskList
		`#$VXDISK list`.each_line do |line|
			#-            -         fusiond02    fusiondev    failed was:c2t48d1s2
			if line =~ / - +(.*?) +(\w+) +failed was:(\w+)/
				diskname = $2 + '.' + $1
				debug "new failed disk: #{diskname} on #{$3}"
				device = findUniqueDisk($3)
				puts "* FAILED DISK FOUND: #{diskname} on #{device}"
				if ! @diskInfo[device]
					@diskInfo[device]=Hash.new
				end

				@diskInfo[device]['vxname'] = diskname
				@diskInfo[device]['vxfail'] = 1
				@vxInfo[diskname] = Hash.new
				@vxInfo[diskname]['device'] = device
				@vxInfo[diskname]['medianame'] = $1
				@vxInfo[diskname]['diskgroup'] = $2
				@vxInfo[diskname]['volumes'] = Array.new
				@vxInfo[diskname]['alloc'] = 0
			end
		end
	end

	def getVxPrint
		dg = nil

		`#$VXPRINT -ht`.each_line do |line|
			# dg acsblprd_dg100 
			if line =~ /^dg (.*?) /
				debug "== new disk group: #{$1}"
				dg=$1
			end

		   # 				dm disk01 c1t71d42s2   sliced   2623     23564160 -
			if line =~ /^dm (.*?) +(\w+) +(\w+) +(\d+) +(\d+)/
				device = findUniqueDisk($2)
				medianame = $1
				diskname = dg + "." + medianame
				debug "new vx disk: #{diskname} on #{$2} (unique: #{device})"
				@diskInfo[device]['vxname'] = diskname
				@vxInfo[diskname] = Hash.new
				@vxInfo[diskname]['device'] = device
				@vxInfo[diskname]['medianame'] = medianame
				@vxInfo[diskname]['diskgroup'] = dg
				@vxInfo[diskname]['device'] = device
				@vxInfo[diskname]['volumes'] = Array.new
				@vxInfo[diskname]['alloc'] = 0
			end
			
			# SD NAME         PLEX         DISK     DISKOFFS LENGTH   [COL/]OFF DEVICE   MODE
			           # sd disk01-01    cti_dev-01   disk01   0        4195200  0         c1t71d42 ENA
			if line =~ /^sd (.*?)-(\d+) +(.*?)-(\d+) +(\w+) +(\d+) +(\d+) +/
				debug "sd: disk=#{$5} vol=#{$3} size=#{$7}"
				medianame = dg + "." + $5
				if ! @vxInfo[medianame]
					puts "* NOTE: #{$3} is on an unknown disk: #{medianame}. You may have VxVM issues!"
				else
					@vxInfo[medianame]['volumes'] << $3
					@vxInfo[medianame]['alloc'] += ($7.to_i / 2)
				end
			end
		end
	end

	
	def uniqueDisks
		@uniqueDisks = Array.new
		seen = Hash.new

		@diskInfo.keys.sort.each do |device|
			serial = @diskInfo[device]['serial']	
			if device =~ /dmp/
				next
			end
			
			if seen[serial]
				debug "adding #{device} to dupe database for #{seen[serial]}"
				@diskInfo[device]['dup'] = seen[serial]
			else
				seen[serial]=device	
				@uniqueDisks << device
			end
		end
		return @uniqueDisks
	end
	
	def outputLine(firstlength, fields)
		printf("%-#{firstlength}.#{firstlength}s %-6.6s %6.6s %6.6s %6.6s %6.6s %4.4s   %-10s\n",
			fields[0], fields[1], fields[2], fields[3], fields[4], fields[5], fields[6], fields[7]);
	end
	
	def diskProducts
		prod = Array.new
		
		@uniqueDisks.each do |dev|
			prod << @diskInfo[dev]['vendor'] + " " + @diskInfo[dev]['brand']
		end
		
		prod.sort.uniq
	end
	
	def calculateProductUsage(prod)
		capacity = 0
		vxvm = 0
		alloc = 0
		disks = 0
		volumesTotal = 0
		volumes = Array.new

		
		@uniqueDisks.each do |dev|
			thisProduct = @diskInfo[dev]['vendor'] + " " + @diskInfo[dev]['brand']
			if prod == thisProduct
				disks += 1
				capacity += @diskInfo[dev]['capacity']

				if @diskInfo[dev]['vxname']
					vx = @diskInfo[dev]['vxname']
					vxvm += @diskInfo[dev]['capacity']
					alloc += @vxInfo[vx]['alloc']
					volumes += @vxInfo[vx]['volumes']
				end
			end
		end
		
		volumes = volumes.sort.uniq
		volumesTotal = volumes.length
			
		return [ capacity, vxvm, alloc, disks, volumesTotal ]
	end
	
	def calculateDiskUsage(disk)
		vxvm = 0
		alloc = 0
		volumes = Array.new

		debug "calculating usage for #{disk}"
		
		capacity = @diskInfo[disk]['capacity']
		if @diskInfo[disk]['vxname']
			vxvm = capacity
			vxname = @diskInfo[disk]['vxname']
			alloc = @vxInfo[vxname]['alloc']
			volumes = @vxInfo[vxname]['volumes']
			diskgroup = @vxInfo[vxname]['diskgroup']
			medianame = @vxInfo[vxname]['medianame']
		else
			debug "no vxname found for disk #{disk}"
		end
		
		return [ capacity, vxvm, alloc, volumes, diskgroup, medianame ]
	end
	
	def displayByProduct
		outputLine(18, [ "Product", "Disks", "Gbytes", "VxVM", "alloc", "avail", "%", "volumes" ])
		columns=78

		puts "-" * (columns-1)
		group = Hash.new
		
		diskProducts.each do |product|
			capacity, vxvm, alloc, disks, volumes = calculateProductUsage(product)
			perc = sprintf("%2.0f%", (alloc.to_f / capacity.to_f) * 100)
			outputLine(18, [ product, disks, capacity / 1024 / 1024, vxvm / 1024 / 1024, alloc / 1024 / 1024,
			 					(capacity - alloc) / 1024 / 1024, perc, volumes])
		end
	
		#outputLine(24, [ "Total", @capacityReal.to_f / 1024 / 1024, 0, 0, 0, "0%", "90" ])
	end
	
	def displayByDisk
		printf("%10.10s %9.9s %4.4s %6.6s %6.6s %6.6s %6.6s %3.3s %-15.15s %s\n",
			"Disk", "ID", "Vendor", "MB", "VxVM", "alloc", "avail", "%", "diskgroup", "medianame");
		columns=90
		puts "-" * (columns-1)
		group = Hash.new
		
		@uniqueDisks.each do |disk|
			capacity, vxvm, alloc, volumes, dg, medianame = calculateDiskUsage(disk)

			perc = sprintf("%2.0f%", (alloc.to_f / capacity.to_f) * 100)

			if @diskInfo[disk]['vxfail'] && medianame
				perc='!!!'
				medianame=medianame + "-FAILED"
			end

			printf("%10.10s %9.9s %4.4s %6.0f %6.0f %6.0f %6.0f %3.3s %-15.15s %s\n", 
				disk.gsub('s2', ''), 
				@diskInfo[disk]['serial'],
				@diskInfo[disk]['vendor'],
				capacity / 1024,
				vxvm / 1024, alloc / 1024,
				(capacity - alloc) / 1024,
				perc,
				dg,
				medianame
				)
		end
	
		#outputLine(24, [ "Total", @capacityReal.to_f / 1024 / 1024, 0, 0, 0, "0%", "90" ])
	end

	def debug(str)
		if ENV['DEBUG']
			puts str
		end
	end
end

info = StorageInfo.new
puts "By Product:\n"
info.displayByProduct
puts "\nBy Disk:\n"
info.displayByDisk

