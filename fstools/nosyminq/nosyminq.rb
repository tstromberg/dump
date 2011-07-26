#!/usr/bin/env ruby
# $Id: nosyminq.rb 530 2005-11-09 22:31:02Z thomas $
# nosyminq 1.0, written by Thomas Stromberg <thomas%stromberg.org>
#
# This command displays what disks a Solaris machine sees, particularly SAN resources. 
# It was modelled after the EMC syminq tool, and has very similar output to it. Here
# are some differences:
#
# * Does not require root to run
# * Does not require the symcli tools to be installed
# * Does not have to be run on a live system, can be passed a filename for iostat -En output
# * Shows disk sizes in MB
# * Shows duplicate paths when detectable
#
# BUGS:
#
# * Does not detect the per-disk serial for EMC CLARiiON devices (Solaris doesn't know it)
# * May confuse paths as duplicates on the same EMC CLARiiON array if the size and disk# are
#   identical.
# * Does not emulate any of syminq's options

class ParseIostat
    def initialize(filename)
        @disk = Hash.new
        if filename
            @output=File.open(filename).readlines
        else
            @output=`iostat -En`
        end
    end

    def parse
        dev=nil
        @output.each do |line|
            if line =~ /^(c\w+)  +Soft Errors: (\d+) Hard Errors: (\d+) +Transport Errors: (\d+)/
                dev=$1
                @disk[dev]=Hash.new
                @disk[dev]['soft_errors']=$2                
                @disk[dev]['hard_errors']=$2                
                @disk[dev]['transport_errors']=$2
#                puts dev
            end      

            # odd one:
            # c1t4d0          Soft Errors: 0 Hard Errors: 0 Transport Errors: 0
            # Vendor: TOSHIBA  Product: DVD-ROM SD-M1711 Revision: 1F05 Serial No: 08/08/03 

            if line =~ /Vendor: (.*?) +Product: (.*?) +Revision: (.*?) +Serial No: (.*)/
                @disk[dev]['vendor'] = $1
                @disk[dev]['product'] = $2
                @disk[dev]['revision'] = $3
				serial = $4.gsub(' ', '')
				if serial.length > 0
	                @disk[dev]['serial']=serial
				else
					@disk[dev]['serial']=''
				end
            end
           
           if line =~ /Size:.*\<([\-\d]+) bytes\>/
                bytes=$1.to_i
                if bytes < 1
                    bytes=0
                end
				#puts "dev #{dev} size is #{bytes}"
                @disk[dev]['size'] = bytes
           end
        end
    end        
    
    def display
        printf("%-9.9s %-4.4s %-9.9s %-20.20s %-6.6s %-14.14s %-s\n", "Device", "Dupe", "Vendor", "ID", "Rev", "Ser Num", "Cap (MB)");
        puts "-" * 72
        
        seen = Hash.new
        @disk.keys.sort.each do |dev|
            serial = @disk[dev]['serial'] + "-" + @disk[dev]['size'].to_s

			# DGC (Clariion) disks have duplicate serial numbers.. this helps clean them up.
			if @disk[dev]['vendor'] == 'DGC'
				dev =~ /d(\d+)/
				serial = serial + @disk[dev]['revision'] + "-" + $1
			end

            if seen[serial]
                dup="#" + seen[serial].to_s
                seen[serial] = seen[serial] + 1
            else
                seen[serial]=2
                dup=""
            end
            
            printf("%-9.9s %-4.4s %-9.9s %-20.20s %-6.6s %-14.14s %-s\n", dev, dup, @disk[dev]['vendor'],
                @disk[dev]['product'], @disk[dev]['revision'], @disk[dev]['serial'], @disk[dev]['size'] / 1024 / 1024)
        end
    end
end

# The run.
io = ParseIostat.new(ARGV[0])
io.parse
io.display
