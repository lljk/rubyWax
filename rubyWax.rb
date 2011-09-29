#! /usr/bin/env ruby

=begin

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

require 'gst'
require 'gtk2'
sep = File::Separator
path = File.join(File.expand_path(File.dirname(__FILE__)), "#{sep}brains#{sep}")
require path + "initWax"
require path + "configmanagerWax"
require path + "lineupWax"
require path + "playlistWax"
require path + "tablelayoutWax"
require path + "transportWax"

Gst.init

rubyWax = Wax.new

Gtk.main