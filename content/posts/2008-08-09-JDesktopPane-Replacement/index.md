---
title: JDesktopPane Replacement
author: Dataforce
type: post
date: 2008-08-09T03:46:49+00:00
url: /2008/08/JDesktopPane-Replacement/
category:
  - Code
  - General

---
As as I [mentioned before](/2008/07/MD5/) I've been recently converting an old project to Java.

This old project was an MDI application, and when creating the UI for the conversion, I found the default JDesktopPane to be rather crappy. Google revealed others thought the same, one of the results that turned up was: http://www.javaworld.com/javaworld/jw-05-2001/jw-0525-mdi.html

So, I created DFDesktopPane based on this code, with some extra changes:

 * Frames can't end up with a negative x/y
 * Respond to resize events of the JViewport parent
 * Iconified icons move themselves to remain inside the desktop at all times.
 * Handles maximised frames correctly (desktop doesn't scroll, option to hide/remove titlebar)

My modified JDesktopPane can be found as [here](http://code.google.com/p/dflibs/source/browse/trunk/java/uk/org/dataforce/swing/DFDesktopPane.java) part of my [dflibs](http://code.google.com/p/dflibs/) Google code project.

Other useful things can be found [here](http://code.google.com/p/dflibs/source/browse/trunk/java/uk/org/dataforce/), take a look and leave any feedback either here or on the project issue tracker
