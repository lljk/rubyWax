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


class ConfigManager < Gtk::ScrolledWindow
	attr_reader :saveBtn1, :saveBtn2
	
 def initialize
		super
		@settings = []
		@sep = File::Separator
		self.readConfig
	
		nb = Gtk::Notebook.new
		
		box0 = Gtk::HBox.new(false, 2)
	
		posbox = Gtk::ComboBoxEntry.new
		posarr = %W[top-left top-right bottom-left bottom-right]
		posarr.collect{|pos| posbox.append_text(pos)}
		posbox.active = posarr.index(@screenpos)
		posbox.signal_connect("changed"){@screenpos = posbox.active_iter[0]}
	
		label0 = Gtk::Label.new("Window Position:")

		box0.pack_start(label0, false, false, 2)
		box0.pack_end(posbox, false, false, 2)
	
		box1 = Gtk::HBox.new(false, 2)
		label1 = Gtk::Label.new("Music Directory:")
		@entrylibdir = Gtk::Entry.new
		@entrylibdir.text = @libdir
		box1.pack_start(label1, false, true, 2)
		box1.pack_end(@entrylibdir, false, true, 2)
	
		box2 = Gtk::HBox.new(false, 2)
		label2 = Gtk::Label.new("Scale % :")
		@entryscale = Gtk::Entry.new
		@entryscale.text = @scale.to_s
		box2.pack_start(label2, false, true, 2)
		box2.pack_end(@entryscale, false, true, 2)

		box3 = Gtk::HBox.new(false, 2)
		label3 = Gtk::Label.new("Show Window Border?")
		@entryborder = Gtk::CheckButton.new
		
		if @border == "true"
			@entryborder.active = true
			
		else
			@entryborder.active = false
		end
		
		box3.pack_start(label3, false, true, 2)
		box3.pack_start(@entryborder, false, true, 2)
	
		box4 = Gtk::HBox.new(false, 2)
		label4 = Gtk::Label.new("Background Color:")
		bgBtn = Gtk::Button.new("Change Color")
		@bgsample = Gtk::EventBox.new
		@bgsample.width_request= 50
		@bgsample.modify_bg(Gtk::STATE_NORMAL, @bgColor)
		bgBtn.signal_connect("button_press_event"){self.bgColorSelect}
		box4.pack_start(label4, false, true, 2)
		box4.pack_end(bgBtn, false, true, 2)
		box4.pack_end(@bgsample, false, true, 2)
	
		@box5 = Gtk::HBox.new(false, 2)
		label5 = Gtk::Label.new("Text Font:")
		@fontBtn = Gtk::Button.new("#{@font}")
		fontdesc = Pango::FontDescription.new(@font)
		@fontBtn.modify_font(fontdesc)
		@fontBtn.signal_connect("button_press_event"){self.fontSelect}
		@box5.pack_start(label5, false, true, 2)
		@box5.pack_end(@fontBtn, false, true, 2)

		box6 = Gtk::HBox.new(false, 2)
		label6 = Gtk::Label.new("Font Color:")
		fcolorBtn = Gtk::Button.new("Change Color")
		@fcsample = Gtk::EventBox.new
		@fcsample.width_request= 50
		@fcsample.modify_bg(Gtk::STATE_NORMAL, @fC)
		fcolorBtn.signal_connect("button_press_event"){self.fontColorSelect}
		box6.pack_start(label6, false, true, 2)
		box6.pack_end(fcolorBtn, false, true, 2)
		box6.pack_end(@fcsample, false, true, 2)
	
		box7 = Gtk::VBox.new(false, 2)
		label7 = Gtk::Label.new
		label7.set_wrap(true)
		label7.text= "Title Formatting\n
		if tags are found\n
		FIELDS:\n
		#track-number#, #title#, #album#, #artist#, #album-artist#, #genre#, #comments#\n
		EXAMPLE:\n
		#track-number#: #title# by #artist# from the album #album#"
		@entryformat = Gtk::Entry.new
		@entryformat.text = @titleformat
		box7.pack_start(label7, false, false, 2)
		box7.pack_start(@entryformat, false, false, 2)
		
		@saveBtn1 = Gtk::Button.new("save and exit")
		@saveBtn2 = Gtk::Button.new("save and exit")
	
		mainBox1 = Gtk::VBox.new(false, 2)
		mainBox2 = Gtk::VBox.new(false, 2)
		mainBox1.pack_start(box1, true, true, 2)
		mainBox1.pack_start(box2, true, true, 2)
		mainBox1.pack_start(box0, true, true, 2)
		mainBox1.pack_start(box3, true, true, 2)
		mainBox1.pack_start(box4, true, true, 2)
		mainBox2.pack_start(@box5, true, true, 2)
		mainBox2.pack_start(box6, true, true, 2)
		mainBox2.pack_start(box7, true, true, 2)
		mainBox1.pack_start(@saveBtn1, false, false, 0)
		mainBox2.pack_start(@saveBtn2, false, false, 0)
	
		label1 = Gtk::Label.new("  general  ")
		label2 = Gtk::Label.new("  title format  ")
	
		nb.append_page(mainBox1, label1)
		nb.append_page(mainBox2, label2)
	
		self.add_with_viewport(nb)
		self.show_all
	end	#initialize

	def bgColorSelect
		d = Gtk::ColorSelectionDialog.new
		sel = d.colorsel
		sel.set_previous_color(@bgColor)
		sel.set_current_color(@bgColor)
		sel.set_has_palette(true)
		response = d.run

		if response == Gtk::Dialog::RESPONSE_OK
			@bgR = sel.current_color.red
			@bgG = sel.current_color.green
			@bgB = sel.current_color.blue
			@bgColor = Gdk::Color.new(@bgR, @bgG, @bgB)
			@bgsample.modify_bg(Gtk::STATE_NORMAL, @bgColor)
		end
		d.destroy
	end	#bgColorSelect

	def fontColorSelect
		d = Gtk::ColorSelectionDialog.new
		sel = d.colorsel
		sel.set_previous_color(@fC)
		sel.set_current_color(@fC)
		sel.set_has_palette(true)
		response = d.run

		if response == Gtk::Dialog::RESPONSE_OK
			@fR = sel.current_color.red
			@fG = sel.current_color.green
			@fB = sel.current_color.blue
			@fC = Gdk::Color.new(@fR, @fG, @fB)
			@fColor = @fC.to_s
			@fcsample.modify_bg(Gtk::STATE_NORMAL, @fC)
		end
		d.destroy
	end	#fontColorSelect

	def fontSelect
		d = Gtk::FontSelectionDialog.new
		d.set_font_name(@font) if @font != nil
		response = d.run
		
		if response == Gtk::Dialog::RESPONSE_OK
			@font = d.font_name
			fontdesc = Pango::FontDescription.new(@font)
			@fontBtn.modify_font(fontdesc)
			@fontBtn.set_label(@font)
		end
		d.destroy
	end	#fontSelect

	def saveSettings
		@entrylibdir.editing_done
		@settings[0] = @entrylibdir.text
		@entryscale.editing_done
		@settings[1] = @entryscale.text
		@settings[2] = @entryborder.active?
		@settings[3] = @bgR
		@settings[4] = @bgG
		@settings[5] = @bgB
		@settings[6] = @font
		@settings[7] = @fR
		@settings[8] = @fG
		@settings[9] = @fB
		@settings[10] = @fColor
		@entryformat.editing_done
		@settings[12] = @entryformat.text
		@settings[15] = @screenpos #@entrypos.text
		self.writeConfig
	end	#saveSettings

	def writeConfig
		f = File.join(File.expand_path(File.dirname(__FILE__)), "#{@sep}config#{@sep}WaxConfig.txt")
		File.delete(f)
		File.new(f, 'w+')
		file = File.open(f, 'a')
		@settings.collect{|index| file.puts(index)}
		file.close
	end	#writeConfig

	def readConfig
		@settings = []
		f = File.join(File.expand_path(File.dirname(__FILE__)), "#{@sep}config#{@sep}WaxConfig.txt")
		file = File.open(f)
		file.collect{|line| @settings << line.chomp}
		@libdir = @settings[0]
		@scale = @settings[1].to_i
		@border = @settings[2]
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
		@titleformat = @settings[12]
		@screenpos = @settings[15]
		file.close
	end	#readConfig

end #class ConfigManager


class Wax
	
	def config
		@config = ConfigManager.new
		@conWin = Gtk::Window.new
		@conWin.signal_connect("destroy"){@conWin = nil}
		@conWin.set_size_request(500, 500)
		@conWin.add(@config)
		@config.saveBtn1.signal_connect("button_press_event"){self.saveConfig}
		@config.saveBtn2.signal_connect("button_press_event"){self.saveConfig}
		@conWin.show_all
	end	#config
	
	def saveConfig
		@config.saveSettings
		@table.children.collect{|child| @table.remove(child)}
		@box.remove(@infoBox)
		@box.remove(@table)
		temp = @batter
		self.readConfig
		@batter = temp
		@table.initUI
	
		@mainWin.remove(@box)
	
		self.initUI
		self.batterUp
		@table.show_all
		@conWin.destroy
		@conWin = nil
	end	#saveConfig	

end	#class Wax