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


class Playlist < Gtk::ScrolledWindow
	attr_accessor :addTrack, :saveExitBtn, :newlist, :box, :view,
	:listselection, :listsBtn, :clrList, :newListBtn
	
	def initialize
		super
		self.set_size_request(450,450)
		self.set_policy(Gtk::POLICY_AUTOMATIC,Gtk::POLICY_AUTOMATIC)
		@sep = File::Separator
		
		@list = Gtk::ListStore.new(String)
		@view = Gtk::TreeView.new(@list)
		@view.reorderable=(true)
		@view.enable_search=(true)
		@view.headers_visible=(false)
		@renderer = Gtk::CellRendererText.new
		@column = Gtk::TreeViewColumn.new("", @renderer, :text => 0)
		@view.append_column(@column)
		@listselection = @view.selection
		@listselection.mode=(Gtk::SELECTION_MULTIPLE)
		self.add(@view)

		@box = Gtk::VBox.new(false,2)
		@addTrack = Gtk::Button.new("add tracks")
		@clrTrack = Gtk::Button.new("clear tracks")
		@clrTrack.signal_connect("button_press_event"){self.clearTracks}
		@clrList = Gtk::Button.new("clear list")
		@listsBtn = Gtk::Button.new("playlists")
		@newListBtn = Gtk::Button.new("save as:")
		@saveExitBtn = Gtk::Button.new("save and exit")
		
		btnbox = Gtk::VBox.new(true, 2)
		btnHbox = Gtk::HBox.new(true, 2)
		btnHbox.pack_start(@addTrack, true, true, 2)
		btnHbox.pack_start(@clrTrack, true, true, 2)
		btnHbox.pack_start(@clrList, true, true, 2)
		btnHbox.pack_start(@listsBtn, true, true, 2)
		btnHbox.pack_start(@newListBtn, true, true, 2)
		btnbox.pack_start(btnHbox, true, true, 2)
		btnbox.pack_start(@saveExitBtn, true, true, 2)
		
		@box.pack_start(self, false, false, 2)
		@box.pack_start(btnbox, false, false, 2)
		
		f = File.expand_path(__FILE__)
		@listDir = File.dirname(f)
		confile = File.open(@listDir + "#{@sep}config#{@sep}WaxConfig.txt", 'r')
		settings = []
		confile.collect{|line| settings << line.chomp}
		@roster = @listDir + "#{@sep}config#{@sep}playlists#{@sep}" + settings[14]
		if File.exists?(@roster)
			@lineUp = []
			list = File.open(@roster, 'r')
			list.collect{|line| @lineUp << line.chomp}
			@lineUp.collect{|entry| self.addToList(File.basename(entry))}
			@longlist = {}
			@lineUp.collect{|entry| @longlist[File.basename(entry)] = entry}
		end
	end	#init
	
	def refreshList
		@list.clear
		confile = File.open(@listDir + "#{@sep}config#{@sep}WaxConfig.txt", 'r')
		settings = []
		confile.collect{|line| settings << line.chomp}
		@roster = @listDir + "#{@sep}config#{@sep}playlists#{@sep}" + settings[14]
		@lineUp = []
		list = File.open(@roster, 'r')
		list.collect{|line| @lineUp << line.chomp}
		@lineUp.collect{|entry| self.addToList(File.basename(entry))}
		@longlist = {}
		@lineUp.collect{|entry| @longlist[File.basename(entry)] = entry}
	end

	def addToList(entry)
		iter = @list.append
		iter[0] = entry
	end

	def clearTracks
		tracks = []
		index = []
		@listselection.selected_each{|mod, path, iter|
			tracks << iter
			index << path.indices[0]
		}
		tracks.collect{|iter, path| @list.remove(iter)}
		index.collect{|i| @lineUp[i] = nil}
		@lineUp.compact!	
	end

	def saveList
		tracks = []
		@newlist = []
		@listselection.select_all
		@listselection.selected_each{|mod, path, iter|
			tracks << iter[0]
		}
		tracks.collect{|entry|
			if @longlist.include?(entry)
				@newlist << @longlist[entry]
			end
		}
		@newlist.compact!
	end

	end	#class

######################################
######################################

class Wax
	
	def loadList(list)
		@roster = @homeDir + "#{@sep}config#{@sep}playlists#{@sep}" + list
	end

	def showPlaylist
		t = File.basename(@roster).split(".")
		winTitle = t[-2]
		@playWin = Gtk::Window.new(winTitle)
		icon = Gdk::Pixbuf.new(@imagedir + "playlist-icon.png")
		@playWin.icon= icon
		@playWin.signal_connect("destroy"){@playWin = nil}
		@playWin.set_size_request(450,525)
		@playlist = Playlist.new
		@playWin.add(@playlist.box)
		@playWin.show_all
		
		unless @lineUp.index(@atBat).nil?
			@focus = Gtk::TreePath.new(@lineUp.index(@atBat))
			@playlist.view.scroll_to_cell(@focus, nil, true, 0.5, 0.5)
			@playlist.listselection.select_path(@focus)
		end
	
	## double-click, play track
		@playlist.view.signal_connect("row-activated"){|view, path, column|
			@batter = path.indices[0]
			self.stopTrack
			if @shuffle == "on"
				@shuffle = "off"
				self.batterUp
				@shuffle = "on"
			else
				self.batterUp
			end
			self.playTrack
		}
	
	## drag and drop
		Gtk::Drag.dest_set(
			@playlist, Gtk::Drag::DEST_DEFAULT_ALL,
			[["text/plain", 0, 0]],
			Gdk::DragContext::ACTION_COPY| Gdk::DragContext::ACTION_MOVE
		)
		
		@playlist.signal_connect("drag_data_received"){|w, context, x, y, data, info, time|
			self.listDataDrop(data, y)
			Gtk::Drag.finish(context, true, false, 0)
			@playlist.refreshList
		}
		
	## add tracks	
		@playlist.addTrack.signal_connect("button_press_event"){
			self.draft
			@playlist.refreshList
		}
		
	## save and exit		
		@playlist.saveExitBtn.signal_connect("button_press_event"){
			@playlist.saveList
			self.lineUpClear
			self.lineUpWrite(@playlist.newlist)
			self.lineUpRead
			self.batterUp if @lineUp[0] != nil
			@playWin.destroy
			@playWin = nil
		}
		
	## playlists	
		@playlist.listsBtn.signal_connect("button_press_event"){self.listDialog}
	
	## clear list	
		@playlist.clrList.signal_connect("button_press_event"){self.clrListSure}
	
	## new list	
		@playlist.newListBtn.signal_connect("button_press_event"){self.saveListAs}
		
	end	#showPlaylist
	
	def listDialog
		@dir = @homeDir + "#{@sep}config#{@sep}playlists#{@sep}"
		
		@pldialog = Gtk::FileChooserDialog.new("playlists",nil,
			Gtk::FileChooser::ACTION_OPEN,
			"gnome-vfs"
		)
		
		icon = Gdk::Pixbuf.new(@imagedir + "playlist-icon.png")
		@pldialog.icon= icon
		@pldialog.select_multiple = false
		@pldialog.current_folder = (@dir)
		@plvbox = Gtk::VBox.new(false, 2)
	
	## load playlist
		selBtn = Gtk::Button.new("load list")
		selBtn.signal_connect("clicked"){
			if @pldialog.filename != nil
				@roster = @pldialog.filename
				self.saveState
				t = File.basename(@roster).split(".")
				winTitle = t[-2]
				@playWin.title= (winTitle)
				@playlist.refreshList
				@playlist.saveList
				@playlist.listselection.unselect_all
				self.stopTrack
				self.lineUpClear
				self.lineUpWrite(@playlist.newlist)
				self.lineUpRead
				@batter = 0
				self.batterUp if @lineUp[0] != nil
			end
		}
		selBtn.show
	
	## close
		closeBtn = Gtk::Button.new("close")
		closeBtn.signal_connect("button_press_event"){@pldialog.hide_all}
		
	## delete playlist
		delBtn = Gtk::Button.new("delete list")
		delBtn.signal_connect("button_press_event"){
			delbox = Gtk::EventBox.new
			label = Gtk::Label.new("delete playlist?")
			btnyes = Gtk::Button.new("delete")
			btnno = Gtk::Button.new("cancel")
			bbox = Gtk::HBox.new(true, 2)
			bbox.pack_start(btnyes, true, true, 2)
			bbox.pack_start(btnno, true, true, 2)
			box = Gtk::VBox.new(false, 2)
			box.pack_start(label, true, true, 2)
			box.pack_start(bbox, false, false, 2)
			delbox.add(box)
			delbox.show_all
			@pldialog.extra_widget = delbox
			
			btnyes.signal_connect("button_press_event"){
				file = @pldialog.filename
				File.delete(file)
				roster = "playlist"
				file = @dir + roster + ".txt"
				list = File.open(file, 'w+')
				list.close
				@roster = file
				self.saveState
				@playlist.refreshList
				t = File.basename(@roster).split(".")
				winTitle = t[-2]
				@playWin.title= (winTitle)
				@pldialog.extra_widget = @plvbox
			}
			btnno.signal_connect("button_press_event"){@pldialog.extra_widget = @plvbox}
		}
		
		hbox = Gtk::HBox.new(true, 0)
		hbox.pack_start(selBtn, true, true, 0)
		hbox1 = Gtk::HBox.new(true, 0)
		hbox1.pack_start(delBtn, true, true, 0)
		hbox1.pack_start(closeBtn, true, true, 0)
		@plvbox.pack_start(hbox, true, true, 0)
		@plvbox.pack_start(hbox1, true, true, 0)
		@plvbox.show_all
		@pldialog.extra_widget = @plvbox
		@pldialog.signal_connect("delete_event"){@pldialog.hide_all}
		@pldialog.show_all
	end	#listDialog

	def saveListAs
		@dir = @homeDir + "#{@sep}config#{@sep}playlists#{@sep}"
		@saveWin = Gtk::Window.new
		@saveWin.set_size_request(250, 150)
		@saveWin.gravity= Gdk::Window::GRAVITY_CENTER
		@saveWin.move(Gdk.screen_width / 2, Gdk.screen_height / 2)
		entrybox = Gtk::HBox.new(false, 2)
		label = Gtk::Label.new("Save As:")
		@entry = Gtk::Entry.new
		entrybox.pack_start(label, false, false, 2)
		entrybox.pack_start(@entry, true, true, 2)
		btnbox = Gtk::HBox.new(true, 2)
		saveList2 = Gtk::Button.new("save")
		cancelSaveBtn = Gtk::Button.new("cancel")
		btnbox.pack_start(saveList2, true, true, 1)
		btnbox.pack_start(cancelSaveBtn, true, true, 1)
		vbox = Gtk::VBox.new(false, 2)
		vbox.pack_start(entrybox, true, true, 2)
		vbox.pack_start(btnbox, false, false, 2)
		@saveWin.add(vbox)
		@saveWin.show_all
		
		cancelSaveBtn.signal_connect("button_press_event"){@saveWin.destroy}
		
		saveList2.signal_connect("button_press_event"){
			@playlist.saveList
			@playlist.listselection.unselect_all
			@entry.editing_done
			roster = @entry.text
			file = @dir + roster + ".txt"
			list = File.open(file, 'w+')
			@playlist.newlist.collect{|item| list.puts(item)}
			list.close
			@roster = file
			@saveWin.destroy
			self.saveState
			@playlist.refreshList
			t = File.basename(@roster).split(".")
			winTitle = t[-2]
			@playWin.title= (winTitle)
		}
	end #saveListAs

	def clrListSure
		@dir = @homeDir + "#{@sep}config#{@sep}playlists#{@sep}"
		@clearBox = Gtk::EventBox.new
		@clearBox.set_size_request(200, 100)
		label = Gtk::Label.new("remove all tracks?")
		btnyes = Gtk::Button.new("remove")
		btnno = Gtk::Button.new("cancel")
		bbox = Gtk::HBox.new(true, 2)
		bbox.pack_start(btnyes, true, true, 2)
		bbox.pack_start(btnno, true, true, 2)
		box = Gtk::VBox.new(false, 2)
		box.pack_start(label, true, true, 2)
		box.pack_start(bbox, false, false, 2)
		@clearBox.add(box)
		@playlist.remove(@playlist.view)
		@playlist.add_with_viewport(@clearBox)
		@playlist.show_all

		btnyes.signal_connect("button_press_event"){
			self.stopTrack
			roster = "playlist"
			file = @dir + roster + ".txt"
			@roster = file
			self.saveState
			t = File.basename(@roster).split(".")
			winTitle = t[-2]
			@playWin.title= (winTitle)
			
			@info = @versioninfo
			@mainWin.remove(@box)
			self.showInfo(@info)
			
			self.lineUpClear
			self.lineUpWrite(@lineUp)
			self.lineUpRead
			self.batterUp
			
			@playlist.refreshList
			@playlist.remove(@clearBox.parent)
			@playlist.add(@playlist.view)
			@playlist.show_all
		}
		
		btnno.signal_connect("button_press_event"){
			@playlist.remove(@clearBox.parent)
			@playlist.add(@playlist.view)
			@playlist.show_all
		}
	end #clrListSure
	
end	#class Wax