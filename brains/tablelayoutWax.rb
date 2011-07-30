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


class TableLayout < Gtk::Layout
	attr_accessor :scale, :box, :bg, :posy, :pos
	
	def initialize
		super
		@sep = File::Separator
		f = File.join(File.expand_path(File.dirname(__FILE__)), "#{@sep}config#{@sep}WaxConfig.txt")
		file = File.open(f)
		settings = []
		file.collect{|line| settings << line.chomp}
		scale = settings[1].to_f
		@scale = (scale.to_f / 100.0)
		@percent = 0
		@box = Gtk::EventBox.new
		@box.signal_connect("expose-event"){|w, e| self.draw(w, e)}
		@box.set_visible_window(false)
		self.initUI
	end	#initialize
	
	def initUI
		f = File.expand_path(__FILE__)
		@dir = File.dirname(f)
		@armf = @dir + "#{@sep}images#{@sep}arm.png"
		@armpx = Gdk::Pixbuf.new(@armf, 146.0 * @scale, 512.0 * @scale)
		@bg = Gtk::Image.new()
		@box.set_size_request(450.0 * @scale, 500.0 * @scale)
		self.set_size(727 * @scale, 589 * @scale)
	end	#initUI
	
	def overlays(state)
		self.remove(@box) if @box.parent != nil
		self.remove(@bg) if @bg.parent != nil
		if state == "playing"
			bgf = @dir + "#{@sep}images#{@sep}stanton1.png"
			bgpx = Gdk::Pixbuf.new(bgf, 727.0 * @scale, 589.0 * @scale)
			@bg = Gtk::Image.new(bgpx) 
		else
			bgf = @dir + "#{@sep}images#{@sep}stanton.png"
			bgpx = Gdk::Pixbuf.new(bgf, 727.0 * @scale, 589.0 * @scale)
			@bg = Gtk::Image.new(bgpx)		
		end
		self.put(@bg, 0, 0)
		self.put(@box, 300.0 * @scale, 10.0 * @scale)
		@bg.show
	end	#overlays
	
	def draw(w, e)
		cc = w.window.create_cairo_context
		cc.translate(622.0 * @scale, 149.0 * @scale)
		cc.rotate((@percent + 18) * Math::PI / 180)
		cc.set_source_pixbuf(@armpx, -109.0 * @scale, -119.0 * @scale)
		cc.paint
	end	#draw

	def update
		@box.queue_draw
	end	#update

	def percent=(percent)
		@percent=((percent * 23) / 100)
		self.update
	end	#percent=

	def defpos
		@posy = @box.pointer[1]
		h = @box.get_size_request[1]
		@pos = (((h - @posy) - (15 * @scale)) / @scale) * 0.80
		@pos = 0.01 if @pos < 0.01
		@pos = 99.9 if @pos > 100.0
	end #defpos
	
	end	#TableLayout
	
#####################################
#####################################

class Wax

	def getDuration
		now = Time.now.sec.to_f
		now = 0.0 if now == 59.0
		@limit = now + 2.0
		
		GLib::Timeout.add(100){
			@qd = Gst::QueryDuration.new(Gst::Format::Type::TIME)
			@pipeline.query(@qd)
			@dur = @qd.parse[1] / 1000000000
			if @dur > 0
				GLib::Timeout.add(100){self.progress}
				false
			elsif
				Time.now.sec.to_f > @limit
				false
			else
				true
			end
		}
	end	#getDuration
	
	def progress
		if @state == "playing"
			q = Gst::QueryPosition.new(Gst::Format::TIME)
			@pipeline.query(q)
			@pos = q.parse[1] / 1000000
			position = @pos.to_f
			duration = @dur * 1000.0
			position = 1.0 if position < 1.0
			ratio = position / duration
			r = ratio * 400.0
			rr = r.round.to_f / 4.0
			rr = 0 if rr < 0
			rr = 100 if rr > 100
			if rr != @r
				@r = rr
				@table.percent=(@r)
			end
			return (Gst::STATE_PLAYING)
		end
	end #progress
	
	def position=(position_in_ms)
		if @pipeline != nil
			@pipeline.send_event(Gst::EventSeek.new(1.0, 
			Gst::Format::Type::TIME, 
			Gst::Seek::FLAG_FLUSH.to_i | Gst::Seek::FLAG_KEY_UNIT.to_i, 
			Gst::Seek::TYPE_SET, position_in_ms * 1000000, Gst::Seek::TYPE_NONE, -1))
		end	#if
	end
	
	def seekToPointer
		if @dur != nil
			@table.defpos
			if @table.posy > 350.0 * @table.scale and @table.posy < 490.0 * @table.scale
				@newpos = (@dur * (@table.pos / 100)) * 1000
				self.position= @newpos
			end
		end
	end	#seekToPointer
	
end	#class Wax