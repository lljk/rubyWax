    rubyWax
    0.11.10 wicked alpha

     ...an audio player for folks who miss their vinyl...

  Hi, and thanks for trying out rubyWax...  it's far from finished, and far from perfect - but it generally runs well at this point, and shouldn't cause any disasters.

  rubyWax requires ruby-gtk2 and gstreamer.

  This "wicked alpha" release is intended for testing, so please - run it, play with it, try to break it, and get back to me with any questions / comments / concerns.

  That said, fire the thing up...  run rubyWax.rb, and off we go!


ADDING TRACKS

  There are 3 ways of adding tracks to playlists.  rubyWax currently plays .mp3, .flac, .ogg, and .wav files.

1.  Drag and drop files or directories onto the "picture-disc" image.  Dropping onto the lower half of the record appends tracks, and onto the upper half prepends them.

2.  Open the playlist, clicking the button in the lower left corner of the table.  Drag and Drop onto the playlist.  Tracks in the playlist can be re-ordered and cleared.

3.  Open the file selection dialog by clicking the "add tracks" button on the playlist.  (note:  you can add a directory in the settings for the file selection dialog to open as default.)

  Playlists can be saved using the "save as:" button, and can be loaded or deleted using the "playlists" button.  If not specified, the current playlist will be saved as "playlist."

  Don't be afraid to load up the playlists - I've dumped my entire music library in at once (52+ gig, and better than 12,000 tracks) with no problem.



PLAYBACK

  The playback buttons should be fairly obvious.  The button in the upper left corner toggles between normal and shuffle playback.

  The tone arm moves with the song's progress, and functions as a seek bar.  Clicking within the range of the arm seeks within the current track.


SETTINGS

  Open the settings dialog with the small button just right of the shuffle button in the upper left corner of the table.

  In the general settings tab, you can set your music library directory for the add tracks dialog, set the scale of the player (from 100% - 30%), turn the window borders on or off, set the default window position, and set the background color.

  In the title format tab you can set the text font, size, and color, and set the tag information to show.  Fields are marked with pound signs (#field#.)  Anything you set in the title format aside from these fields will be shown as is.  For example, if you are listening to the seventh track of "Electric Ladyland,"  tags are available, and you have set the title format to be:  #track-number#: #title# - by #artist#, from the groovy album #album#  ---  you will see: "07: Come On (Let the Good Times Roll) - by Jimi Hendrix, from the groovy record Electric Ladyland   --- otherwise the file's name will be displayed.


COVER ART

  The image shown as the "picture disc" will be the first image file (.jpg, .png, or .gif,) found in the playing track's directory, or the default album image if none is found.


COMING SOON

  The playlist is quite (maybe overly) simple in this release - because I barely use the thing...  Later versions should have a more functional playlist for sorting tracks.
  I'm also working on a graphical music directory browser, which would be strictly eye-candy as the filechooser dialog works just fine.
  For the moment, there is no volume control - you'll have to use your system volume, sorry!

SO......

  Load up your favorite tunes and give it a go.  Please get back to me with any problems / concerns / suggestions.

  rock and roll, buddy...

  -jk
  
