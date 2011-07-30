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
	
	def playpauseTrack
		oldimage = @playBtn.children[0]
		
		if @atBat != nil
			
			if @state == "stopped"
				@playBtn.name= "1pause.png"
				@playBtn.remove(oldimage)
				playpx = Gdk::Pixbuf.new(@imagedir + @playBtn.name, @bsize * @table.scale, @bsize * @table.scale)
				playimage = Gtk::Image.new(playpx)
				@playBtn.add(playimage)
				@playBtn.show_all
				self.playTrack
				
			elsif @state == "paused"
				@playBtn.name= "1pause.png"
				@playBtn.remove(oldimage)
				playpx = Gdk::Pixbuf.new(@imagedir + @playBtn.name, @bsize * @table.scale, @bsize * @table.scale)
				playimage = Gtk::Image.new(playpx)
				@playBtn.add(playimage)
				@playBtn.show_all
				self.resumeTrack
				
			else
				@playBtn.name= "1play.png"
				@playBtn.remove(oldimage)
				playpx = Gdk::Pixbuf.new(@imagedir + @playBtn.name, @bsize * @table.scale, @bsize * @table.scale)
				playimage = Gtk::Image.new(playpx)
				@playBtn.add(playimage)
				@playBtn.show_all
				@state = "paused"
				@table.overlays(@state)
				self.buttons		
				self.pauseTrack
			end
			
		else
			notrack = "no tracks loaded"
			self.showInfo(notrack)
		end
	end	#playpauseTrack
	
	def playTrack
		if @atBat != nil
			
			if File.exists?(@atBat)
				@pipeline = Gst::ElementFactory.make("playbin2")
				@pipeline.uri= @atBatURI
				bus = @pipeline.bus
				@tagMsg = []
				bus.add_watch {|bus, message|
					case message.type
						when Gst::Message::ERROR
						p message.parse
						Gtk.main_quit
						when Gst::Message::EOS
						self.nextTrack
						when Gst::Message::TAG
						@tagMsg << message.structure.entries
						self.getTags
					end
					true
				}
				oldimage = @playBtn.children[0]
				@playBtn.remove(oldimage)
				@playBtn.name= "1pause.png"
				playpx = Gdk::Pixbuf.new(@imagedir + @playBtn.name, @bsize * @table.scale, @bsize * @table.scale)
				playimage = Gtk::Image.new(playpx)
				@playBtn.add(playimage)
				@playBtn.show_all
				@state = "playing"
				@table.overlays(@state)
				self.buttons
				@pipeline.play	
				self.getDuration
	
			else
				@info = "file: #{@atBat} not found"
				self.showInfo(@info)
			end
	
		else
			@info = "no tracks loaded"
			@cover.pixbuf= @noimg
			@box.remove(@infoBox)
			@box.remove(@table)
			@mainWin.remove(@box)
			@state = "stopped"
			self.showTable
		end  # if @atBat != nil
	end	# playTrack
	
	def shuffleTrack
		@pipeline.stop if @pipeline != nil
		
		if @batter != nil
			@batter = rand(@lUpine.length)
			
			if @lUpine[@batter] != nil
				@state = "playing"
				self.batterUp
				self.playTrack
				
			else
				@info = "no track"
				self.showInfo(@info)
			end
			
		else
			@info = "no track"
			self.showInfo(@info)
		end	
	end	#shuffleTrack
	
	def nextTrack
		@pipeline.stop if @pipeline != nil
		
		if @batter != nil
			@batter = @batter + 1
			
			if @lineUp[@batter] != nil
				@state = "playing"
				self.batterUp
				self.playTrack
				
			else
				@info = "no track"
				self.showInfo(@info)
			end
			
		else
			@info = "no track"
			self.showInfo(@info)
		end
	end	# nextTrack
	
	def prevTrack
		@pipeline.stop if @pipeline !=nil
		
		if @batter != nil
			@batter = @batter -1
			
			if @lineUp[@batter] != nil
				self.batterUp
				self.playTrack
				
			else
				self.stopTrack
				@info = "no previous track"
				self.showInfo(@info)
			end
			
		else
			@info = "no track"
			self.showInfo(@info)	
		end
	end	 #prevTrack
	
	def stopTrack
		@pipeline.stop if @pipeline != nil
		@state = "stopped"
		oldimage = @playBtn.children[0]
		@playBtn.remove(oldimage)
		@playBtn.name= "1play.png"
		playpx = Gdk::Pixbuf.new(@imagedir + @playBtn.name, @bsize * @table.scale, @bsize * @table.scale)
		playimage = Gtk::Image.new(playpx)
		@playBtn.add(playimage)
		@playBtn.show_all
		@table.overlays(@state)
		self.buttons
	end  #stopTrack
	
	def pauseTrack
		@pipeline.pause if @pipeline != nil
		@state = "paused"
	end #pauseTrack
	
	def resumeTrack
		@pipeline.play
		@state = "playing"
		@table.overlays(@state)
		self.buttons
		GLib::Timeout.add(100){self.progress}
	end
	
	def buttons
		@bsize = 68
		@playBtn = Gtk::EventBox.new
		@playBtn.set_visible_window(false)
		
		if @state != "playing"
			@playBtn.name= "1play.png"
			
		else
			@playBtn.name= "1pause.png"
		end
		
		playpx = Gdk::Pixbuf.new(@imagedir + @playBtn.name, @bsize * @table.scale, @bsize * @table.scale)
		playimage = Gtk::Image.new(playpx)
		@playBtn.add(playimage)
		@playBtn.signal_connect("button_press_event"){self.playpauseTrack}
		@playBtn.signal_connect("enter_notify_event"){self.enterEvent(@playBtn)}
		@playBtn.signal_connect("leave_notify_event"){self.leaveEvent(@playBtn)}
		@playBtn.show_all
		@table.put(@playBtn, 568.0 * @table.scale, 508.0 * @table.scale)
		
		@prevBtn = Gtk::EventBox.new
		@prevBtn.set_visible_window(false)
		@prevBtn.name= "1prev.png"
		prevpx = Gdk::Pixbuf.new(@imagedir + @prevBtn.name, @bsize * @table.scale, @bsize * @table.scale)
		previmage = Gtk::Image.new(prevpx)
		@prevBtn.add(previmage)
		@prevBtn.signal_connect("button_press_event"){self.prevTrack}
		@prevBtn.signal_connect("enter_notify_event"){self.enterEvent(@prevBtn)}
		@prevBtn.signal_connect("leave_notify_event"){self.leaveEvent(@prevBtn)}
		@prevBtn.show_all
		@table.put(@prevBtn, 489.0 * @table.scale, 508.0 * @table.scale)
		
		@nextBtn = Gtk::EventBox.new
		@nextBtn.set_visible_window(false)
		@nextBtn.name= "1next.png"
		nextpx = Gdk::Pixbuf.new(@imagedir + @nextBtn.name, @bsize * @table.scale, @bsize * @table.scale)
		nextimage = Gtk::Image.new(nextpx)
		@nextBtn.add(nextimage)
		@nextBtn.signal_connect("button_press_event"){self.nextTrack}
		@nextBtn.signal_connect("enter_notify_event"){self.enterEvent(@nextBtn)}
		@nextBtn.signal_connect("leave_notify_event"){self.leaveEvent(@nextBtn)}
		@nextBtn.show_all
		@table.put(@nextBtn, 645.0 * @table.scale, 508.0 * @table.scale)
		
		@dgBtn = Gtk::EventBox.new
		@dgBtn.set_visible_window(false)
		@dgBtn.name= "1dugout.png"
		dgpx = Gdk::Pixbuf.new(@imagedir + @dgBtn.name, @bsize * @table.scale, @bsize * @table.scale)
		dgimage = Gtk::Image.new(dgpx)
		@dgBtn.add(dgimage)
		@dgBtn.signal_connect("button_press_event"){
			if @playWin == nil
				self.showPlaylist
				
			else @playWin.destroy
				@playWin = nil
			end
		}
		@dgBtn.signal_connect("enter_notify_event"){self.enterEvent(@dgBtn)}
		@dgBtn.signal_connect("leave_notify_event"){self.leaveEvent(@dgBtn)}
		@dgBtn.show_all
		@table.put(@dgBtn, 11.0 * @table.scale, 506.0 * @table.scale)
		
		cfgpx = Gdk::Pixbuf.new(@imagedir + "config.png", 33.0 * @table.scale, 33.0 * @table.scale)
		cfgimage = Gtk::Image.new(cfgpx)
		@cfgBtn = Gtk::EventBox.new.add(cfgimage)
		@cfgBtn.name= "config.png"
		@cfgBtn.signal_connect("button_press_event"){
			if @conWin == nil
				self.config
			else @conWin.destroy
				@conWin = nil
			end
		}
		@cfgBtn.signal_connect("enter_notify_event"){self.enterEvent(@cfgBtn)}
		@cfgBtn.signal_connect("leave_notify_event"){self.leaveEvent(@cfgBtn)}
		@cfgBtn.show_all
		@table.put(@cfgBtn, 107.0 * @table.scale, 14.0 * @table.scale)
		
		@shufBtn = Gtk::EventBox.new
		@shufBtn.set_visible_window(false)
		
		if @shuffle != "off"
			@shufBtn.name = "1shuffle.png"
			shufpx = Gdk::Pixbuf.new(@imagedir + @shufBtn.name, @bsize * @table.scale, @bsize * @table.scale)
		else
			@shufBtn.name = "1default.png"
			shufpx = Gdk::Pixbuf.new(@imagedir + @shufBtn.name, @bsize * @table.scale, @bsize * @table.scale)
		end
	
		shufimage = Gtk::Image.new(shufpx)
		@shufBtn.add(shufimage)
		@shufBtn.show_all
		@table.put(@shufBtn, 13.0 * @table.scale, 11.0 * @table.scale)
	
		@shufBtn.signal_connect("button_press_event"){
			@shufBtn.remove(@shufBtn.children[0])
			
			if @shuffle == "on"
				@batter = @lineUp.index(@atBat)
				@shufBtn.name= "1default.png"
				shufpx = Gdk::Pixbuf.new(@imagedir + @shufBtn.name, @bsize * @table.scale, @bsize * @table.scale)
				shufimage = Gtk::Image.new(shufpx)
				@shufBtn.add(shufimage)
				@shufBtn.show_all
				@shuffle = "off"
				
			else
				@batter = @lUpine.index(@atBat)
				@shufBtn.name= "1shuffle.png"
				shufpx = Gdk::Pixbuf.new(@imagedir + @shufBtn.name, @bsize * @table.scale, @bsize * @table.scale)
				shufimage = Gtk::Image.new(shufpx)
				@shufBtn.add(shufimage)
				@shufBtn.show_all
				@shuffle = "on"
			end
		}
		
		@shufBtn.signal_connect("enter_notify_event"){self.enterEvent(@shufBtn)}
		@shufBtn.signal_connect("leave_notify_event"){self.leaveEvent(@shufBtn)}
		
		@mainWin.show_all
	end	#buttons

end	#class Wax