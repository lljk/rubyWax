=begin
	
	this file is part of:
    rubyWax
    v 0.11.10
    
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
	
	def lineUpRead
		@lineUp = []
		
		if File.exists?(@roster)
			list = File.open(@roster, 'r+')
			list.collect{|line| @lineUp << line.chomp}
			@lUpine = @lineUp.shuffle
			list.close
			
		else
			@info = "no valid playlist to load"
			self.showInfo(@info)
		end
		
		@lineUp.compact!
		@lUpine.compact!
	end

	def lineUpWrite(line_up = [])
		file = @roster
		list = File.open(file, 'w+')
		line_up.collect{|item| list.puts(item)}
		list.close
	end

	def lineUpClear
		file = @roster
		File.new(file,'w+')
		@lineUp = []
	end

	def lineUpAppendDir(dir)
		Dir.chdir(dir)
		all = Dir["**#{@sep}*.*"]
		all = all.sort
		all.collect{|entry|
			@okfiles.collect{|type|
				if entry.downcase.include? type
					fname = dir + @sep + entry
					@lineUp << fname
				end
			}
		}
	end

	def lineUpPrependDir(dir)
		Dir.chdir(dir)
		all = Dir["**#{@sep}*.*"]
		all = all.sort
		all = all.reverse
		all.collect{|entry|
			@okfiles.collect{|type|
				if entry.downcase.include? type
					fname = dir + @sep + entry
					@lineUp.insert(0, fname)
				end
			}
		}
	end

	def draft
		if File.directory?(@libdir.to_s)
			dialog = Gtk::FileChooserDialog.new(
				"add tracks",nil,
				Gtk::FileChooser::ACTION_OPEN,
				"gnome-vfs"
			)
			icon = Gdk::Pixbuf.new(@imagedir + "draft-icon.png")
			dialog.icon= icon
			dialog.select_multiple = true
			dialog.current_folder = ("#{@libdir}")
			
			audioFilter = Gtk::FileFilter.new
			audioFilter.name = "audio"
			audioFilter.add_pattern("*.mp3"); audioFilter.add_pattern("*.MP3")
			audioFilter.add_pattern("*.wav"); audioFilter.add_pattern("*.WAV")
			audioFilter.add_pattern("*.flac"); audioFilter.add_pattern("*.FLAC")
			audioFilter.add_pattern("*.ogg"); audioFilter.add_pattern("*.OGG")
			dialog.add_filter(audioFilter)
	
			appBtn = Gtk::Button.new("list...<<")
			appBtn.signal_connect("clicked"){
				selection = dialog.filename
				
				if File.directory?(selection)	
					Gtk::FileChooser::ACTION_SELECT_FOLDER
					temp = @lineUp
					self.lineUpClear
					@lineUp = temp
					@batter = 0 if @lineUp.empty?
					self.lineUpAppendDir(selection)
					
				else
					Gtk::FileChooser::ACTION_OPEN
					temp = @lineUp
					self.lineUpClear
					@lineUp = temp
					@batter = 0 if @lineUp.empty?
					@lineUp << selection
				end
				
				self.lineUpWrite(@lineUp)
				self.lineUpRead
				self.batterUp if @state == "stopped"
				@playlist.refreshList
			}
			
			appBtn.show
		
			preBtn = Gtk::Button.new(">>...list")
			preBtn.signal_connect("clicked") {
				selection = dialog.filename
				
				if File.directory?(selection)	
					Gtk::FileChooser::ACTION_SELECT_FOLDER
					temp = @lineUp
					self.lineUpClear
					@lineUp = temp
					@batter = 0 if @lineUp.empty?
					self.lineUpPrependDir(selection)
					
				else
				Gtk::FileChooser::ACTION_OPEN
				temp = @lineUp
				self.lineUpClear
				@lineUp = temp
				@batter = 0 if @lineUp.empty?
				@lineUp.insert(0, selection)
				end
			
				self.lineUpWrite(@lineUp)
				self.lineUpRead
				self.batterUp if @state == "stopped"
				@playlist.refreshList
			}
			
			preBtn.show
		
			closeBtn = Gtk::Button.new("close")
			closeBtn.signal_connect("button_press_event"){dialog.destroy}
		
			vbox = Gtk::VBox.new(false, 2)
			hbox = Gtk::HBox.new(true,0)
			hbox.pack_start(preBtn,true,true,0)
			hbox.pack_start(appBtn,true,true,0)
			vbox.pack_start(hbox,true,true,0)
			vbox.pack_start(closeBtn,true,true,0)
			vbox.show_all
			dialog.extra_widget = vbox
			dialog.signal_connect("delete_event"){dialog.destroy}
			dialog.run
			
		else
			@libdir = @homeDir
			self.draft
		end	#if
	end	# draft

	def tableDataDrop(data, y)
		self.browserTableDrop(data, y) if data.include?("browserdata\n")
		
		if data.include?("file:#{@sep}#{@sep}")
			arr = data.split("file:#{@sep}#{@sep}")
			pop = arr.pop
			raw = pop.chomp
			name = self.cleanUp(raw)
			
		else
			name = data
		end
		
		if y > (@table.height) / 2
			
			if File.file?(name)
				@okfiles.collect{|type|
					if name.downcase.include? type
						temp = @lineUp
						self.lineUpClear
						@lineUp = temp
						@lineUp << name
					end
				}
				
			elsif File.directory?(name)
				temp = @lineUp
				self.lineUpClear
				@lineUp = temp
				self.lineUpAppendDir(name)
			end
		
		elsif y < (@table.height) / 2
			
			if File.file?(name)
				@okfiles.collect{|type|
					if name.downcase.include? type
					temp = @lineUp
					self.lineUpClear
					@lineUp = temp
					@lineUp.insert(0, name)
					end
				}
				
			elsif File.directory?(name)
				temp = @lineUp
				self.lineUpClear
				@lineUp = temp
				self.lineUpPrependDir(name)
			end
		end #if y> elsif y<
		
		self.lineUpWrite(@lineUp)
		self.lineUpRead
		self.batterUp if @state == "stopped"
		@playlist.refreshList if @playlist != nil
	end	#tableDataDrop

	def listDataDrop(data, y)
		arr = data.data.split("file:#{@sep}#{@sep}")
		pop = arr.pop
		raw = pop.chomp
		name = self.cleanUp(raw)
		
		if File.file?(name)
			@okfiles.collect{|type|
				if name.downcase.include? type
					temp = @lineUp
					self.lineUpClear
					@lineUp = temp
					@lineUp << name
				end
			}
			
		elsif File.directory?(name)
			temp = @lineUp
			self.lineUpClear
			@lineUp = temp
			self.lineUpAppendDir(name)
		end	#if File.file?
		
		self.lineUpWrite(@lineUp)
		self.lineUpRead
		self.batterUp if @state == "stopped"
		@playlist.refreshList
	end	#listDataDrop

	def browserTableDrop(data, y)
		datarray = data.split("\n")
		datarray.delete_at(0)
		datarray.each{|entry| tableDataDrop(entry, y)}
	end

	def browserListDrop(data, y)
		p "got here!"
	end
	
	def cleanUp(str)
		str = str.gsub("%20", " ")
		str = str.gsub("%60", "`")
		str = str.gsub("%23", "#")
		str = str.gsub("%25", "%")
		str = str.gsub("%5B", "[")
		str = str.gsub("%5D", "]")
		str = str.gsub("%7B", "{")
		str = str.gsub("%7D", "}")
		str = str.gsub("%7C", "|")
		str = str.gsub("%3F", "?")
		str = str.gsub("%3C", "<")
		str = str.gsub("%3E", ">")
		str = str.gsub("%5E", "^")
	end	#cleanUp
	
end	#class Wax