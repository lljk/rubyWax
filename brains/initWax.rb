=begin
	
	this file is part of:
    rubyWax
    v 0.11.08
    
     an audio player for folks who miss their vinyl

    Copyright (C)  2011 Justin Kaiden

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end


class Wax
	attr_reader :mainWin
		
	def initialize
	
		@versioninfo = "rubyWax v.0.11.08"
		@info = @versioninfo
	
		f = File.expand_path(__FILE__)
		@homeDir = File.dirname(f)
		@sep = File::Separator
	
		self.readConfig
		self.loadList(@list)
	
		@table = TableLayout.new
	
		@imagedir = @homeDir + "#{@sep}images#{@sep}"
		@lineUp = []
		@r = 0
		@state = "stopped"
		@okfiles = %W[.mp3 .flac .ogg .wav]
		
		@noimg = Gdk::Pixbuf.new(@imagedir + "record.png", 485.0 * @table.scale, 485.0 * @table.scale)
		@cover = Gtk::Image.new(@noimg)
		
		@mainWin = Gtk::Window.new('')
		@mainWin.signal_connect("destroy"){
			@pipeline.stop if @pipeline != nil
			self.saveState; Gtk.main_quit
		}
	
		icon = Gdk::Pixbuf.new(@imagedir + "turntable-icon.png")
		@mainWin.icon= icon
	
		@box = Gtk::VBox.new(false, 2)
		@infoBox = Gtk::EventBox.new()
		@infoTxt = Gtk::Label.new
		@infoBox.add(@infoTxt)
	
		@mainWin.set_size_request(727.0 * @table.scale, 589.0 * @table.scale + @infoBox.size_request[1])
	
		@table.box.signal_connect(
			"button_press_event"){self.seekToPointer}
			Gtk::Drag.dest_set(@table, Gtk::Drag::DEST_DEFAULT_ALL,
			[["text/plain", 0, 0]],
			Gdk::DragContext::ACTION_COPY| Gdk::DragContext::ACTION_MOVE
		)
	
		@table.signal_connect("drag_data_received"){|w, context, x, y, data, info, time|
			self.tableDataDrop(data.data, y)
			Gtk::Drag.finish(context, true, false, 0)
		}
	
		self.initUI
		self.lineUpRead
	
		@batter = @lineUp.index(@atBat) if @shuffle != "on"
		@batter = @lUpine.index(@atBat) if @shuffle == "on"
		self.batterUp if @lineUp[0] != nil
	end	#initialize

	def initUI
		@infoTxt.width_chars=(@table.width * 0.13)
		@infoTxt.set_wrap(true)
		@infoTxt.justify=(Gtk::JUSTIFY_CENTER)
		
		@mainWin.resize(727.0 * @table.scale, (589.0 * @table.scale) + @infoBox.size_request[1] + 10)
		
		if @border.downcase == "false"
			@mainWin.decorated= false 
		
		else
			@mainWin.decorated= true
		end
		
		@mainWin.modify_bg(Gtk::STATE_NORMAL, @bgColor)
		@infoBox.modify_bg(Gtk::STATE_NORMAL, @bgColor)

		if @screenpos.downcase == "top-left"
			@box.pack_start(@table, true, true, 2)
			@box.pack_start(@infoBox, false, false, 2)
			@mainWin.gravity= Gdk::Window::GRAVITY_NORTH_WEST
			@mainWin.move(2 , 2)
	
		elsif @screenpos.downcase == "top-right"
			@box.pack_start(@table, true, true, 2)
			@box.pack_start(@infoBox, false, false, 2)
			@mainWin.gravity= Gdk::Window::GRAVITY_NORTH_EAST
			@mainWin.move(Gdk.screen_width - (@mainWin.width_request + 2), 2)

		elsif @screenpos.downcase == "bottom-left"
			@box.pack_start(@infoBox, false, false, 2)
			@box.pack_start(@table, true, true, 2)
			@mainWin.gravity= Gdk::Window::GRAVITY_SOUTH_WEST
			@mainWin.move(2, Gdk.screen_height - (@mainWin.height_request + 2))
		
		else
			@box.pack_start(@infoBox, false, false, 2)
			@box.pack_start(@table, true, true, 2)
			@mainWin.gravity= Gdk::Window::GRAVITY_SOUTH_EAST
			@mainWin.move(Gdk.screen_width - (@mainWin.width_request + 2), Gdk.screen_height - (@mainWin.height_request + 2))
		end

		self.showTable
	end	#initUI

	def showTable
		if @cover.pixbuf=(@noimg)
			@noimg = @noimg.scale(485.0 * @table.scale, 485.0 * @table.scale)
			@cover = Gtk::Image.new(@noimg)
		end
	
		@table.put(@cover, 49.0 * @table.scale, 51.0 * @table.scale)
		@table.overlays(@state)
	
		self.showInfo(@info)
		@mainWin.add(@box)
		self.buttons
	
		@mainWin.show_all
	end	#showTable

	def batterUp
		case @shuffle
			when "off"
			@batter = 0 if @batter == nil
			@batter = 0 if @batter > @lineUp.length
			@atBat = @lineUp[@batter]
			when "on"
			@batter = 0 if @batter == nil
			@batter = 0 if @batter > @lUpine.length
			@atBat = @lUpine[@batter]
		end
	
		if @atBat != nil
			@atBatURI = GLib.filename_to_uri(@atBat)
			#parts = @atBat.split(@sep)
			#pop = parts.pop
			#dir = parts.join(@sep)
			dir = File.dirname(@atBat)
			Dir.chdir(dir)
			files = Dir['*.{jpg,JPG,png,PNG,gif,GIF}']
			filename = files[0]
			filename = "nofile.jpg" if filename == nil
		
			if File.exist?(filename)
				pix = Gdk::Pixbuf.new(filename)
				img = pix.scale(485.0 * @table.scale, 485.0 * @table.scale)
			else
				pix = Gdk::Pixbuf.new(@imagedir + "record.png")
				img = pix.scale(485.0 * @table.scale, 485.0 * @table.scale)
			end
	
			@table.remove(@cover)
			@cover = Gtk::Image.new(img)
			@cover.show
			@table.remove(@table.bg)
			@table.remove(@table.box)
			@table.put(@cover, 49.0 * @table.scale, 51.0 * @table.scale)
			@table.overlays(@state)
			self.buttons	
		
		else
			@cover.pixbuf=(@noimg)
			self.showTable
		end
	end  #batterUp

	def getTags
		@gotTags = false
		@tags = @tagMsg.flatten
		if @tags.include?("title")
			@title = @tags[@tags.index("title") + 1]; @gotTags = true
		else @title = nil; end
		if @tags.include?("artist")
			@artist = @tags[@tags.index("artist") + 1]; @gotTags = true
		else @artist = nil; end
		if @tags.include?("album")
			@album = @tags[@tags.index("album") + 1]; @gotTags = true
		else @album = nil; end
		if @tags.include?("comments")
			@comments = @tags[@tags.index("comments") + 1]; @gotTags = true
		else @comments = nil; end
		if @tags.include?("track-number")
			@tracknumber = @tags[@tags.index("track-number") + 1]; @gotTags = true
		else @tracknumber = nil; end
		if @tags.include?("genre")
			@genre = @tags[@tags.index("genre") + 1]; @gotTags = true
		else @genre = nil; end
		if @tags.include?("album-artist")
			@albumartist = @tags[@tags.index("album-artist") + 1]; @gotTags = true
		else @albumartist = nil; end

		split = @titleformat.split("#")
		@infoentries = []
	
		split.collect{|i|
			i = @title if i == "title"
			i = @album if i == "album"
			i = @artist if i == "artist"
			i = @genre if i == "genre"
			i = @albumartist if i == "album-artist"
			i = @tracknumber if i == "track-number"
			i = @comments if i == "comments"
			@infoentries << i
		}

		if @gotTags == false
			@info = File.basename(@atBat)
			self.showInfo(@info)
			
		else
			@infoentries.compact!
			@info = @infoentries.join
			@info = @info.gsub("&", "&amp;")
			@info = @info.gsub("<", "&lt;")
			@info = @info.gsub(">", "&gt;")
			self.showInfo(@info)
		end
	end #getTags

	def showInfo(info)
		@infoTxt.set_markup(%Q[<span font_desc="#{@font}" foreground="#{@fColor}">#{info}</span>])
		@infoBox.show_all
		@mainWin.resize(727.0 * @table.scale, 589.0 * @table.scale + @infoTxt.size_request[1] + 10)
	end	#showInfo

	def enterEvent(widget)
		child = widget.children[0]
		old = widget.name
		arr = old.split(".")
		h = @imagedir + arr[0] + "HOVER"
		arr[0] = h
		new = arr.join(".")
		widget.remove(child)
		newpix = Gdk::Pixbuf.new(new, child.pixbuf.width, child.pixbuf.height)
		image = Gtk::Image.new(newpix)
		widget.add(image)
		widget.show_all
	end	#enterEvent

	def leaveEvent(widget)
		child = widget.children[0]
		old = widget.name
		arr = old.split("HOVER")
		n = arr.join
		new = @imagedir + n
		widget.remove(child)
		newpix = Gdk::Pixbuf.new(new, child.pixbuf.width, child.pixbuf.height)
		image = Gtk::Image.new(newpix)
		widget.add(image)
		widget.show_all
	end	#leaveEvent

	def readConfig
		@settings = []
		@confile = @homeDir + "#{@sep}config#{@sep}WaxConfig.txt"
	
		if File.exists?(@confile)
			file = File.open(@confile, 'r')
			file.collect{|line| @settings << line.chomp}
			@libdir = @settings[0].to_s
			@scale = @settings[1].to_f
			@scale = 100.0 if @scale > 100.0
			@scale = 30.0 if @scale < 30.0
			@table.scale = (@scale.to_f / 100.0) if @table != nil
			@border = @settings[2].to_s
			@bgR = @settings[3].to_i
			@bgG = @settings[4].to_i
			@bgB = @settings[5].to_i
			@bgColor = Gdk::Color.new(@bgR, @bgG, @bgB)
			@font = @settings[6]
			@fR = @settings[7].to_i
			@fG = @settings[8].to_i
			@fB = @settings[9].to_i
			@fC = Gdk::Color.new(@fR, @fG, @fB)
			@fColor = @settings[10]
			@shuffle = @settings[11]
			@titleformat = @settings[12]
			@atBat = @settings[13]
			@list = @settings[14].to_s
			@screenpos = @settings[15]
			file.close
		
		else
			settings = ["none", "50", "true", "0", "0", "0", "FreeSans 11", "58853", "58853", "58853", "#e5e5e5e5e5e5", "off", "#artist# - #album# - #title#", "nil", "playlist.txt", "bottom-right"]
			file = File.new(@confile, 'w+')
			settings.collect{|item| file.puts(item)}
			file.close
			self.readConfig
		end
	end	#readConfig

	def saveState
		@settings[11] = @shuffle
		@settings[13] = @atBat
		roster = @roster.split(@sep)
		file = roster[-1]
		@settings[14] = file
		@settings[15] = @screenpos
		file = @homeDir + "#{@sep}config#{@sep}WaxConfig.txt"
		File.delete(file)
		File.new(@homeDir + "#{@sep}config#{@sep}WaxConfig.txt", 'w+')
		file = File.open(@homeDir + "#{@sep}config#{@sep}WaxConfig.txt", 'a')
		@settings.collect{|index| file.puts(index)}
		file.close
	end	#saveState

end	#Class Wax