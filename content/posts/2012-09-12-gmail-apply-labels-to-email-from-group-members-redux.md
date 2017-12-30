---
title: GMail – apply labels to email from group members – Redux
author: Dataforce
type: post
date: 2012-09-12T01:30:18+00:00
url: /2012/09/gmail-apply-labels-to-email-from-group-members-redux/
categories:
  - Code
  - General

---
[A while ago](/2008/08/GMail-apply-labels-to-email-from-group-members/) I posted a python script that allowed automatically adding labels to gmail messages based on contact groups.

Unfortunately, a side effect of this script was that Google occsaionally would lock an account out for "suspicious activity", and for this reason I stopped using the script.

However recently I looked at [Google Apps Scripts](http://script.google.com/) to see if this would allow me to recreate this using Google-Approved APIs, and the good news is, yes it does.

The following script implements the same behaviour as the old python script. It checks every thread from the past 2 dates (so today, and yesterday) and then for each message in the thread gets the list of groups the sender is in (if the sender is a contact, and in any groups) and then checks to see if there are labels that match the same name, if so it applies them to the message.

To get this running, create a new project on the google apps script page, then paste the code in.

Modify `scheduledProcessInbox` and `processInboxAll` to include a label prefix if desired (eg `contacts/`) and then enable the desired schedule (click on the clock icon in the toolbar). Once this has been scheduled you can run an initial pass over the inbox using `processInboxAll()` - however this is limited to the last 500 threads.

The code can now be found [here on github](http://github.com/ShaneMcC/GMailGroupLabeller)

Any questions/comments/bugs please leave them here or on github.
