---
title: "Sleep-tracking and me"
author: Dataforce
url: /2025/06/sleeptracking-and-me/
image: sleepbot.png
type: post
date: 2025-06-19T14:27:00Z
category:
  - General
  - Code
---

What if I told you I've tracked every single night of sleep for the past 14 years using an app that's basically been dead for over a decade?

If you actually know me, then it probably comes as no surprise at all. Anyone who has spent any considerable amount of time chatting with me will know a few things about me:

1. I don't like change[^1].
2. I like graphs and data.
3. I do not always have the best relationship with sleep[^2].

So when I say "I've been tracking my sleep and graphing[^3] it, since August 2010, using the same app[^4]" the response is likely to be one, or both, of "of course you have..." or "but, why?"

The app in question is [SleepBot](https://en.wikipedia.org/wiki/SleepBot) which is one of the early arrivals on the sleep tracking scene and the initial premise was fairly simple. You press a button to say you went sleep, and another when you finished. And then you can rate the sleep and write some notes about it. This button can be in the app itself or a widget on your homescreen. *Importantly* - it also drew graphs.

Eventually you could also put the app on your bed next to you and it would record any unusual sounds you made, or motion you made. And it had a smart alarm feature, and it had web-sync capabilities. I never really used any of these features other than the basic tracking.

<!--more-->

**Unfortunately** the app has been undeveloped since 2013, and even removed from the play store. The cloud service shut down many years ago and was buggy and seemingly broken (at least for me) for many years prior to that. (Though this does mean that the app never succumbed to the same level of enshittification that occurs these days with pretty much everything.) I've tried other apps but not ever managed to find one that does the bits I wanted[^5].

**Fortunately** while it's not available on the play store, I do have an APK that I can sideload onto my phone[^6], and the developers handily thought to include a backup and export/import feature that has allowed me to move my data from device-to-device over the years.

So since August 2010[^7] I have fairly religiously tapped in/out on the app when I went to sleep, dutifully resetting the sleep sessions if I failed to get to sleep, to give me a "mostly accurate" picture of my sleep since then. For example the last 12 months looks something like this[^8]:

{{< postimage src="graph_year.png" side="middle" alt="Last Year Sleep Graph" >}}

I say "mostly accurate" - obviously it relies on me manually tapping in/out, so I need to remember to do that (Which I pretty much always do[^9]), or I need to remember to reset the timings if I don't sleep well.

There are also some issues with sleeping in different timezones, or the fact the graphs are really only designed to handle up to the last 360 days. Beyond that, the only other option is "all" which is a bit of a mess and not useful:

{{< postimage src="graph_all.png" side="middle" alt="All-time Sleep Graph" >}}

But these are minor and the raw data still falls into the "good enough and interesting enough to keep going" bucket.

There have however been a couple of incidents where I have lost some tracking data over the years.

The first of these (September 2019), was mostly my own fault, I was using [magisk](https://en.wikipedia.org/wiki/Magisk_(software)) on my phone at the time[^10] and tried to install a plugin that went terribly wrong resulting in an unusable and bricked phone that I was unable to recover. I was unfortunately on holiday at the time away from home and couldn't spend sufficient time to try and figure out ways to unbrick it (which I'm sure existed) because I needed a phone the next day and it was 1am and ended up just having to factory reset. At the time my last backup of the sleep data was a month old.

This annoyed me, a lot, but I vowed to just remember to take more frequent backups of the data and see if I could get their cloud sync service working. (Spoiler: I could not, it would let me login but failed to actually sync and the web ui didn't really seem to behave properly either.)

The second data loss incident (October 2023), wasn't my fault and was due to a [bug](https://issuetracker.google.com/issues/305766503?pli=1) in android 14 where the phone basically [bricked itself](https://linustechtips.com/topic/1538248-pixel-phones-using-multiple-profiles-are-being-soft-bricked-by-newest-os-update/) if you had multiple profiles enabled. In this case my last backup was only a week prior - but this still also annoyed me a lot[^11].

After this second incident it became apparent to me that "any" data loss annoyed me, so after this I decided to sit down and figure out if I could intercept the cloud sync process and grab the data myself and just store it in a database to do something with later. I'm [no stranger](https://github.com/shanemcc/moneytracker) to intercepting web traffic and reverse-engineering web requests to get access to data, so I figured this would be pretty straight forward.

> As an unrelated side note here, I do wish that API Access to my own data was a more common thing, it's my data I should have access to it.
>
> The fact that OpenBanking/PSD2 didn't *actually* directly provide this was most upsetting. Or the fact that institutions will provide limited access despite being capable of more - a good example of this is one of my banks in the UK. Via the online banking portal I can download "the last 12 months of transactions" in a "computer-friendly format"
>
> But, if I instead sniff some cookies from chrome devtools there is actually a JSON API (that the online banking website uses to display transactions) that I can get much more complete transaction data from, going all the way back to when the account was first opened. Why can I not have a nice way to access this properly?
>
> I digress...

I told myself at the time "I'll do the basic data-collection now, and then worry later about things like reverse-sync (syncing from server to phone) or drawing my own graphs etc". Obviously, this bit never happened[^12]...

I use [pi-hole](https://pi-hole.net/) at home, so I figured I could easily intercept the DNS for `mysleepbot.com` and point it to my own server and then try and figure out what it was doing. If I could do that I could try and emulate the sync service to capture the data, and just store it in a database. I also have a dedicated wifi network with [mitmproxy](https://mitmproxy.org/) running on the gateway for sniffing traffic from phones if needed, though I didn't end up using it for this.

Turns out, reverse-engineering the sync and getting the data was reasonably straight-forward in the end. (Though at this point, you'll have to forgive me for not having the foresight to note down more of what I did so that I could write a blog post about it 2 years later.)

Because it's an android application, I was able to decompile it with `jadx` (a tool that converts Android apps back into readable Java code) and get a *reasonably* acceptable version of code that I could look at to help find the details of the cloud sync process rather than just blindly guessing from web requests. The process mostly just involved initial registration/login and then repeated calls to a sync end point. There was also a "check for updates" endpoint.

With this knowledge, I was able to write a very-bodgy PHP script that emulated enough of the SleepBot server (I only really needed to handle the 4 mentioned endpoints, though there looks to be a few more) to convince the app to not only send it all the sleep data it had recorded so far - but to also keep sending it every time I used it or made changes.

This was great - when I was at home - but didn't quite satisfy me enough. So I also then ended up editing the decompiled source code (or at least, some version of it. I have `JADX` output and `smali` output of various parts of the app that I edited and was able to re-build and re-sign somehow) that I had to actually point it at one of my own domains rather than `mysleepbot.com` so that it worked from anywhere.

And this has been happily chugging away now for the last year and a half collecting all the data, and allowing me to not have to worry about the data loss any more! (I'd say this helped me sleep better, but it really really did not change anything.)

So here I am, 14 years later, still using the same dead app, but now with working cloud sync to keeping the data safe. And as I've been sitting on this data for a while now, maybe it's about time I did something more interesting with it than just... collecting it and occasionally holding a graph at people and going "look! a fun graph!"

In a later post, I'll go into some details about what I've done and how I did it, and talk about how it might even be time for me to retire the sleepbot app at last.


[^1]: I just like things to be the way I like them! It's fine!
[^2]: I'm reliably informed, this is an understatement. I am getting better though, honest!
[^3]: I've definitely probably shown you the graph, and surprise, you're going to see it again later in this post.
[^4]: See #1.
[^5]: I'm apparently [not the only one](https://www.reddit.com/r/androidapps/comments/nucxnz/desperately_looking_for_sleep_logging_alternative)
[^6]: with increasing levels of difficulty as android starts to complain about the version of the OS the app was written for
[^7]: This gets increasingly further and further away...
[^8]: Seeeeeeeeee, I said I was getting better!
[^9]: Though I don't tend to stop/start it in the night if I quickly get out of bed for a few minutes to use the toilet or get a drink
[^10]: I had unlocked the bootloader, and that broke the ability to use ~~Android~~GooglePay without root hiding. It was a massive faff, I just don't bother to unlock the bootloader now as I never really took advantage of doing it after the [G1](https://en.wikipedia.org/wiki/HTC_Dream) or [Nexus](https://en.wikipedia.org/wiki/Google_Nexus) phones, and even then, barely.
[^11]: Turns out, I hate losing *any* amount of data, who knew?!
[^12]: This would be a pretty pointless blog post if this was entirely accurate. But you'll have to read the next one for that, this one is just scene-setting. Sorry.
