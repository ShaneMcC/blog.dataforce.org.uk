---
title: Captcha Woes
author: Dataforce
type: post
date: 2006-12-22T03:22:22+00:00
url: /2006/12/Captcha-Woes/
category:
  - General

---
Even the most complex captchas can be bypassed, if not tested thoroughly enough.

Some time ago, I implemented a captcha on my comments form for news posts, to stop spam bots. My captcha is quite complicated, and sometimes generates images that even humans strugle on, yet for some reason i managed to get 10788 spam comments!

I immediatly tested my captcha - tried with no value, a wrong value, a right value, only the right one worked.

Then I tried in a different window, open 2 tabs to the same comment, submit the 2nd one with no data and get told the correct captcha, then try using that on the first window, this also didn't work - however, it told me the correct captcha was "", upon hitting back and trying with no captcha, it worked.

Turns out I had forgot to make "" an invalid captcha when testing if the values were correct, seeing as when you submit the captcha, it clears the captcha session, a blank value WAS indeed the same value that was stored in the session! The spambots were just not accepting the session, and thus had a blank captcha - and by them not filling in the captcha, and not accepting the session, they were able to submit comments. This has now been fixed, and a blank captcha will now give an error of "Captcha Timeout".

Fortunatly, 3 Simple SQL Queries pruned the lot :) 1 of which pruned 7900+. Silly bots being so similar!
