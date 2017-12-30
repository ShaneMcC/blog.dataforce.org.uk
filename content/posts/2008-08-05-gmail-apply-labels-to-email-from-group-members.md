---
title: GMail – apply labels to email from group members
author: Dataforce
type: post
date: 2008-08-05T06:03:27+00:00
url: /2008/08/gmail-apply-labels-to-email-from-group-members/
category:
  - Code
  - General
  - IRC

---
**NOTE:** The information in this article has been superceeded by [this one](/2012/09/gmail-apply-labels-to-email-from-group-members-redux/).

* * *

As Noted by [Chris](http://chris.smith.name/) recently on IRC, [Google Mail](http://gmail.com) lacks a feature in its ability to automatically label/filter messages - you can't do it based on emails from people in a contact group, short of adding a filter with all their email address on it.

At the time it was mentioned this didn't affect me, however later when I got round to adding loads of labels/filters in gmail (yay for, nicely coloured inbox!) to nicely separate things for me I also ran into this problem, so came up with the following python script that does it for me.

It checks messages, sees if the sender is in the contacts, then checks each group to see if there is a label with that group name that is not already set, then checks to see if the contact is in the group, and finally sets the label if everything matches up.

I ran it initially to tag my entire inbox (set `checkAllIndex` to `True` change `ga.getMessagesByFolder(folderName)` to `ga.getMessagesByFolder(folderName, True)`) and now have it running on a 15 minute cron (not using loopMode) to tag new messages for me.

Hopefully this will be useful to someone else, I'm not sure how well it works in general, it worked fine for me with ~700 messages at first, however after a few runs (due to regrouping some contacts) I was greeted by an `Account Lockdown: Unusual Activity Detected` message when trying to do anything - This went away after about 20 minutes, but don't say you wern't warned if it happens to you.

{{< prettify python >}}
#!/usr/bin/env python
"""
 This script will login to gmail, and add labels to messages for contact groups.

 By default the script will only check items from the past 2 days where email
 was recieved.

 Loop mode can be enabled to save logging in repeatedly from cron.
 Loop mode may fail after some time if google kills the session, or gmail
 becomes unavailable or so. (Untested in these situations). On the other hand
 it may also just keep running indefinetly as if no problem occured, loop mode
 is relatively untested and was added as an after thought.

 When running in loop mode, it is best to have a crontab entry also that checks
 and restarts the script if it dies.

 Copyright 2008 Shane 'Dataforce' Mc Cormack

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
"""

# Uncomment the lines below if python can't find libgmail on its own, and edit
# the sys,path.insert to point to where libgmail.py is.

# import sys
# sys.path.insert(0, 'libgmail')
import libgmail
import time

###############################################################################
# Configuration
###############################################################################

# Email Address
email = "YOUR EMAIL HERE"
# Password
password = "YOUR PASS HERE"
# Check all on index, rather than just the first 2 dates found
checkAllIndex = False
# Use Loop (if true the script will keep looping, and sleep between checking
# for new mail to modify)
useLoop = False
# Time in seconds to sleep when looping (300 = 5 mins)
loopTime = 300
# Label Prefix - if group-based labeles are prefixed, set the prefix here.
# (eg "Groups/")
labelPrefix = ""
# What folder to check? ('inbox' or 'all' are probbaly the most common settings)
folderName = 'inbox'

###############################################################################
# Helper classes/methods
###############################################################################

class ContactGroup:
	def __init__(self, id, name, contacts):
		self.id = id
		self.name = name
		self.contacts = contacts

	def containsContact(self, contact):
		for knownContact in self.contacts:
			if knownContact[0] == contact.id:
				return True
		return False

		def __str__(self):
			return self.name

# Get Contacts and Groups
# Modified from libgmail 0.1.10 to include groups aswell
def getContacts(account):
	"""
	Returns a GmailContactList object
	that has all the contacts in it as
	GmailContacts
	"""
	contactList = []
	groupList = []
	# pnl = a is necessary to get *all* contacts
	myUrl = libgmail._buildURL(view='cl',search='contacts', pnl='a')
	myData = account._parsePage(myUrl)
	# This comes back with a dictionary
	# with entry 'cl'
	addresses = myData['cl']

	# Now loop through the addresses and get the contacts
	for entry in addresses:
		if len(entry) &gt;= 6 and entry[0]=='ce':
			newGmailContact = libgmail.GmailContact(entry[1], entry[2], entry[4], entry[5])
			contactList.append(newGmailContact)

	contacts = libgmail.GmailContactList(contactList)

	# And now, the groups
	for entry in addresses:
		if entry[0]=='cle':
			newGroup = ContactGroup(entry[1], entry[2], entry[5])
			groupList.append(newGroup)

	return contacts, groupList

###############################################################################
# Setup
###############################################################################

print "Running.."
print "Use Loop:", useLoop
if useLoop:
	print "  Loop Time:", loopTime
print "Check all on index:", checkAllIndex
print "Label Prefix:", labelPrefix
print "Checking Folder:", folderName
print "libgmail Version:", libgmail.Version
print ""

# Login to gmail
print "Logging in as", email
ga = libgmail.GmailAccount(email, password)
ga.login()

# Loop at least once.
loop = True;

while loop:
	loop = useLoop

	print "Getting label names.."
	# Get Labels
	labels = ga.getLabelNames(refresh=True)
	# Get Messages
	print "Getting messages.."
	inbox = ga.getMessagesByFolder(folderName)
	# Get Contacts
	print "Getting contacts and groups"
	contacts, groups = getContacts(ga)

	# Check each thread in the inbox
	lastDate = '';
	secondDate = False;
	for thread in inbox:
		# Only check dates we are supposed to.
		if not checkAllIndex:
			# Get the date
			threadDate = thread.__getattr__('date');
			# Make sure a date is set
			if lastDate == '':
				lastDate = threadDate

			# If this date is different to the last one do something.
			if lastDate != threadDate:
				# If we are already on the second date, then we stop now
				if secondDate:
					break;
				# Otherwise, if the new data is a non-time date, we can change to the
				# second date.
				elif "am" not in threadDate and "pm" not in threadDate:
					lastDate = threadDate
					secondDate = True

		print "Thread:", thread.id, len(thread), thread.subject, thread.getLabels(), thread.__getattr__('date'), thread._authors, thread.__getattr__('unread')
		try:
			# Current Labels
			threadCurrentLabels = thread.getLabels();
			# We will add labels here first to prevent dupes
			threadLabels = set([])
			# Check each message in the thread.
			for msg in thread:
				print "  Message:", msg.id, msg.sender
				# Check if sender is a known  contact
				contact = contacts.getContactByEmail(msg.sender)
				if contact != False:
					# Check each group for this contact
					for group in groups:
						# If we have a label with this group name
						labelName = labelPrefix+group.name
						if (labelName in labels) and (labelName not in threadCurrentLabels):
							# And the group contains the contact we want
							if group.containsContact(contact):
								# Add it to the list
								print "    Sender Label:", labelName
								threadLabels.add(labelName)
		except Exception, detail:
			print "  Error parsing messages:", type(detail), detail

		# Now add the labels
		for label in threadLabels:
			print "  Adding Label:", label
			thread.addLabel(label)
		# If thread was unread, make it unread again.
		if thread.__getattr__('unread'):
			print "  Remarking as unread"
			ga._doThreadAction("ur", thread)

	if loop:
		print ""
		print "Sleeping"
		time.sleep(loopTime)
	else:
		print "Done"
{{< /prettify >}}

On a related note, I've also recently started to use the "[Better Gmail 2](https://addons.mozilla.org/en-US/firefox/addon/6076)" addon for firefox (Official page seems down atm, but more info [here](http://lifehacker.com/software/exclusive-lifehacker-download/better-gmail-2-firefox-extension-for-new-gmail-320618.php)) mostly for the grouping of labels feature.

**Edit:** Script will now preserve unread status of threads.
