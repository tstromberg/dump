#!/usr/bin/env ruby
# $Id: trussmap.rb 516 2005-11-04 02:11:26Z thomas $
# 
# trussmap 1.0
# 
# This script will generate an SVG process tree map based on the output of the
# Solaris "truss -df" command. It is trivial to add support for other operating
# systems.
#
## [syntax ] ###################################################################
#
# ./trussmap.rb [options] <truss.file>
#
## [zlib license] ##############################################################
# Copyright (c) 2005 Thomas Stromberg
# This software is provided 'as-is', without any express or implied warranty. In
# no event will the authors be held liable for any damages arising from the use
# of this software. Permission is granted to anyone to use this software for any
# purpose, including commercial applications, and to alter it and redistribute it
# freely, subject to the following restrictions:
# 1. The origin of this software must not be misrepresented; you must not claim
#that you wrote the original software. If you use this software in a product, an
# acknowledgment in the product documentation would be appreciated but is not
# required.
# 2. Altered source versions must be plainly marked as such, and must not be
# misrepresented as being the original software.
# 3. This notice may not be removed or altered from any source distribution.
################################################################################
require 'optparse'

class TrussMap
	attr_accessor :levelHeight, :filterMinimum, :showPid, :height, :width, :timePoints
	def initialize
        @pidmap = Hash.new
        @height = 1024
        @points = Hash.new
        @width = 1600
		
		@filterMinimum=0.4
		@drawLines = Array.new
		@drawBoxes = Array.new
		@drawText = Array.new
		
        @lowest = Hash.new
        @reservations = Hash.new
    
        @levelHeight = 180
        @timePoints = 5
		@showPid = nil
    end
	
    def parseSolarisTruss(file)
		# truss sometimes prints lines without a time, so we cheat and use the time
		# of the last process that had it.
		lastTime = nil
	
        File.open(file).readlines.each { |line|
		  case line
		  	when /^(\d+):\s+([\d\.]+)\s+execve\(\"(.*?)\"/
		  	    pid = $1.to_i
		        if (! @pidmap[pid])
    			    @pidmap[pid] = Hash.new
    			    @pidmap[pid]['start']=$2.to_f
                end
                @pidmap[pid]['name']=$3
				#@pidmap[pid]['start']=$2.to_f
				#puts "#{pid} is #{$3}"
				
			when /^(\d+):\s+([\.\d]+)\s+v*fork.*?\(\).*returning as child.*?= (\d+)/
                pid = $1.to_i
                @pidmap[pid] = Hash.new 
				@pidmap[pid]['start']=$2.to_f
                @pidmap[pid]['parent'] = $3.to_i;
				@pidmap[pid]['name']=@pidmap[$3.to_i]['name']
				#puts "#{pid}'s parent is #{@pidmap[pid]['parent']}"

			when /^(\d+):\s+.*releasing \.\.\./
				pid = $1.to_i
				#puts "found aborted pid #{pid}: #{$2}"
				@pidmap[pid]['end'] = lastTime
				
            when /^(\d+):\s+([\.\d]+).*exit/
                pid = $1.to_i
				#puts "found exit for #{pid}: #{$2}"
                @pidmap[pid]['end'] = $2.to_f
				lastTime = $2.to_f
			when /^(\d+):\s+([\.\d]+).*signal/
                pid = $1.to_i
				#puts "found signal for #{pid}: #{$2}"
                @pidmap[pid]['end'] = $2.to_f
				lastTime = $2.to_f

		  end
        }
    end
    
    def displayHeader
        puts "<?xml version=\"1.0\" standalone=\"no\"?>"
        puts "<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.0//EN\" \"http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd\">"
        puts "<svg width=\"#{@realWidth}\" height=\"#{@height}\" x=\"0\" y=\"0\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999 xlink\">"
    end
    
    def displayFooter
        puts "</svg>"
    end

    # dntest:                177......291
    # psio:                 144.................497
        
    def detectCollision(x, y, width, height)
        @points.each_key { |pnt|
			# does the proposed box start in the middle of another box?
            if (@points[pnt]['y1'] == y) && (x < @points[pnt]['x2']) && (x >= @points[pnt]['x1'])
                return pnt
            end
			# does the proposed box end in the middle of another box?
            if (@points[pnt]['y1'] == y) && ((x+width) > @points[pnt]['x1']) && ((x+width) < @points[pnt]['x2'])
                return pnt
            end
            
			# does the proposed box end in the middle of a box? 
            if (@points[pnt]['y1'] == y) && (x < @points[pnt]['x1']) && ((x+width) > @points[pnt]['x2'])
                return pnt
            end
        }
        return nil
    end
    
    def displayGrid
        timePoint=@width / (@totalLength / @timePoints)
        #puts "my timepoint is #{timePoint}"
        time = 0
        1.step(@width, timePoint) { |x|
            puts "<line x1=\"#{x}\" y1=\"0\" x2=\"#{x}\" y2=\"#{@height}\" style=\"stroke:rgb(180,240,240);stroke-width:1; stroke-dasharray: 1, 3;\"/>"
            puts "<text x=\"#{x}\" y=\"25\" font-size=\"8\">#{time}s</text>"  
            time = time + @timePoints
        }

        level = 0
        1.step(@height, @levelHeight) { |y|
            puts "<line x1=\"0\" y1=\"#{y}\" x2=\"#{@width}\" y2=\"#{y}\" style=\"stroke:rgb(100,180,180);stroke-width:2\"/>"    
            puts "<text x=\"15\" y=\"#{y+@levelHeight-12}\" style=\"fill: rgb(210,210,210); font-size: 15pt;\">Fork Level #{level}</text>"  
            level = level + 1
        }
        
    end
    
    def generateBlocks(parent, level)
        height=14
        children = Array.new   
        duration = @pidmap[parent]['end'] - @pidmap[parent]['start']
        x = (@width * (@pidmap[parent]['start'] / @totalLength)).to_i

		# filter out processes that run faster than a certain period of time
		if duration < @filterMinimum
			return
		end
		
        width=((duration / @totalLength) * @width).to_i
            
        if @pidmap[parent]['name']
            name = @pidmap[parent]['name']
        else
			pparent = @pidmap[parent]['parent']
			puts "pparent is #{pparent}"
			puts "pparent name is #{@pidmap[pparent]['name']}"
            name = @pidmap[pparent]['name'] + ":" + parent.to_s
        end

        # reserve a point for the pid
		y = (level * @levelHeight) + 1
		if @showPid
			text = sprintf("%s[%i]: %.1fs", File.basename(name), parent, duration)
		else
			text = sprintf("%s: %.1fs", File.basename(name), duration)
		end
		textWidth = text.length * 8
		reserveWidth = width
		textX = x + 3
		
		# first, shorten it.
		if textWidth > width
				text = sprintf("%s", File.basename(name).gsub(/\.sh$/, ''))
				textWidth = text.length * 8
		end
		
		# then move it to the right.
		if textWidth > width
				reserveWidth = width + textWidth
				textX = x + width + 3
		end

        collision=1
        while collision
            collision = detectCollision(x, y, reserveWidth, height)
            if (collision)
                y=y+height
            end
        end
      
        @points[parent] = Hash.new
        @points[parent]['x1'] = x
        @points[parent]['y1'] = y
        @points[parent]['box_x2'] = x + width
        @points[parent]['x2'] = x + reserveWidth
        @points[parent]['y2'] = y + height        
		textY = y + 11
        
		if (@points[parent]['x2'] > @realWidth)
			@realWidth = @points[parent]['x2']
		end
		
        linkpid=@pidmap[parent]['parent']        
        if linkpid
            @drawLines << "<line x1=\"#{x+(width / 2)}\" y1=\"#{y}\" x2=\"#{@points[linkpid]['x1'] + ((@points[linkpid]['box_x2'] - @points[linkpid]['x1']) / 2)}\" y2=\"#{@points[linkpid]['y2']}\" style=\"stroke:rgb(#{@pidmap[linkpid]['linkcolor']});stroke-width:1;fill-opacity: 0.4;\"/>"
        end
        
		@drawBoxes << "<rect x=\"#{x}\" y=\"#{y}\" width=\"#{width}\" height=\"#{height}\" style=\"fill:rgb(#{@pidmap[parent]['linkcolor']}); stroke:rgb(25,25,25); fill-opacity: 0.4; stroke-width:1\"/>"
		# debugging only. puts a red box around the reserved area.
		#@drawBoxes << "<rect x=\"#{x}\" y=\"#{y}\" width=\"#{reserveWidth}\" height=\"#{height}\" style=\"fill:rgb(#{@pidmap[parent]['linkcolor']}); stroke:rgb(255,0,0); fill-opacity: 0.2; stroke-width:1\"/>"
		@drawText << "<text x=\"#{textX}\" y=\"#{textY}\" style=\"fill: rgb(40,40,40); font-size: 8pt;\">#{text}</text>"

        @pidmap.each_key {|pid|
            if @pidmap[pid]['parent'] == parent
                children << pid
            end
        }
        
        if children.length > 0
            newlevel = level + 1
            children.each { |child|
                generateBlocks(child, newlevel)
            }
        end
    end

	def pickColor
		lineR = rand(128) + 128
		lineG = rand(128) + 128
		lineB = rand(128) + 128
		return "#{lineR},#{lineG},#{lineB}"
	end
	
	def displayContent
		puts @drawLines.join("\n")
		puts @drawBoxes.join("\n")
		puts @drawText.join("\n")
	end
	
    def display
		bigcheese = nil
		@realWidth = @width

        @pidmap.each_key {|pid|
			# assign the colors
			@pidmap[pid]['linkcolor'] = pickColor

			# determine primary pid
            if ! @pidmap[pid]['parent']
				bigcheese=pid
		    end
		}
        
		#puts "big cheese is #{bigcheese}, it's end is #{@pidmap[bigcheese]['end'], start is #{@pidmap[bigcheese]['start']}"
			
		@totalLength = @pidmap[bigcheese]['end']
		generateBlocks(bigcheese, 0)
		displayHeader
		displayGrid
		displayContent
		displayFooter
    end
end


### actual execution instructions #############################################
opts = OptionParser.new
map = TrussMap.new

opts.banner = "Usage: trussmap [options] <trussfile>"
opts.on("-x", "--width=1600", "Width of graphic") { |x| map.width=x.to_i }
opts.on("-y", "--height=1028", "Height of graphic") { |y| map.height=y.to_i }
opts.on("-h", "--height=200", "Height of each fork level (bad hack for now)") { |h| map.levelHeight=h.to_i }
opts.on("-p", "--showpid", "Show process id's") { map.showPid=1 }
opts.on("-m", "--minimum=0.4", "Minimum amount of run time for a process to show up on the map (seconds)") { |time| map.filterMinimum=time.to_f }
opts.on_tail("-h", "--help")   { puts opts; exit }  
opts.parse!(ARGV)

if ! ARGV[0]
        puts opts
        exit
end

map.parseSolarisTruss(ARGV[0])
map.display

