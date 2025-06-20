---
title: "Thoughts on AI and LLMs for Coding"
author: Dataforce
url: /2025/06/thoughts-on-ai-and-llms-for-coding/
image: postimg.png
type: post
date: 2025-06-20T01:30:00Z
category:
  - General
  - Code
  - AI
---

AI in coding, Hype or genuinely helpful? I've always leaned towards 'hype' but a recent dive into using it for some real-world tasks started to shift my perspective... slightly.

I've long been generally skeptical of "AI" in all its forms. The idea behind it is fun, the technology is fun (if ethically problematic[^1]), but overall I've been rather underwhelmed.

I've pretty much had access to ChatGPT from the beginning. I've asked it questions and felt underwhelmed by the replies (I know it has gotten better). I've seen the hallucinations on things I *know* about, so I feel like can't really trust it on things I don't[^2]. It talks confidently, it sounds convincing, it's probably entirely hallucinated. I have however also then seen friends using it to analyse games of online [werewolf](https://en.wikipedia.org/wiki/Mafia_(party_game)) and summarise that day's activities and chat to help them keep up when they're too busy. It's usually at least able to follow and accurately report on 50% of what is happening (it can't *read people* though yet, so ymmv).

On the image side, I've used Stable Diffusion to generate images[^3] of myself[^4]. I've also used image generation tools like [Midjourney](https://www.midjourney.com/) since the early days and seen it go from strength to strength. I've used it for quick throwaway joke images, but never really managed to get it to do *quite* what I had in mind (though usually good enough for a joke). I've also used and seen friends using [Bing Image Creator](https://www.bing.com/images/create) to great success to generate meme-images for in-jokes among friend groups.

And while these tools are usually "good enough", I've also then seen them generate 6-fingered people or obviously fake images. I've also laughed at the [Will Smith eating spaghetti test](https://en.wikipedia.org/wiki/Will_Smith_Eating_Spaghetti_test) (and then been impressed at the later improvements to this) or the fact [LLMs can't spell strawberry](https://techcrunch.com/2024/08/27/why-ai-cant-spell-strawberry/).

And I know other people have more success with it. I'm constantly being bombarded on social media by posts from people saying how AI is going to put people out of jobs, and that if you're not spending 50% of your day in ChatGPT you're wasting your time. But despite this I've just not succumbed to the hype, all my experience to date was very firmly at the level of "Meh, It's 'ok'. Not good. Certainly not a tool I expect to use all day every day".

But earlier this month I finally dipped my first toe into the LLM/AI Coding pool...

<!--more-->

I've recently read and discussed [Chris'](https://chameth.com/) post [about LLMs](https://chameth.com/coming-around-on-llms/) and using [Claude Code](https://www.anthropic.com/claude-code), and also found myself talking to a non-developer friend who was using [Google Gemini](https://gemini.google.com/) to write a tool to help us moderate werewolf games at [Manchester Werewolf](https://werewolves.club/) rather than doing it by hand or our current powerpoint-based solution and was having a decent level of success with it.

As it happens the next day at work I had a need to bulk add around 50 people to [netbox](https://github.com/netbox-community/netbox) (A tool used to track network and datacenter assets) based only on their email addresses. The email addresses were all uniform `firstname.lastname@company.com` style addresses, I needed all the users to be created with a random password, a known set of permissions and to correctly set the name fields in netbox. I also wanted to then have a list of the users and passwords so I could get them distributed.

This is the sort of thing I would normally quickly knock a script out for myself to do (having become quite familiar with pynetbox for other work-related tools) but decided to see if I could speed things up by getting Google Gemini to do it. I had a free trial for a month of access to the Pro tier, so why not?

I started off with a pretty easy prompt:

> Hi Gemini, I'd like some help writing a quick python script to interact with netbox using `pynetbox` if you can assist with this.
> I have a list of users (that should be read from a `users.txt` file) and I need the script to the create the user accounts.
> The list will consist of a list of email address in the format `firstname.lastname@company.com` and the users should be created with the username as the part before the `@`, their full email address, and their name correctly extracted based on the known address format.
> Users should be added to a predefined set of groups that will be specified in the code.
> A random 20-character password should be generated for each user, and the code should output a list of users that have been created and their passwords.
> If a user already exists, do not recreate them or make any changes.

And watched it get to work. And work it did. A python script was produced, that did exactly what I wanted. It even looked pretty sensible overall. It also gave a lot of spurious unneeded extra information like how to run it and explained a bit about how it worked and what it was doing. Useless to me, but maybe more useful to a non-developer. Importantly, it did it in less than a minute, far far quicker than I would have done.

I ran it.

It did the job, as desired.

However then I realised then the passwords it was generating were... too complicated for some of the users in question. And also, I'd missed a group on the permissions I needed to give all the users. I could have modified the script myself to fix this, deleted the users I'd just created and then tried again, but at this point I was slightly-invested in seeing what Gemini would do.

Prompt #2[^5]:

> Thanks for that, works great, some minor changes:
> I'd like a command line flag `--update` that will make it update users if they exist to ensure they are in the correct set of groups (but make no other changes to that user)
> I'd also like an additional flag `--resetpassword` that will create a new password for the users (and output it at the end)
> In the case of a user that is not already existing, then the old behaviour is fine and these flags will make no difference.
> Finally, can we change the password algorithm - I only want it to generate alphanumeric passwords (no symbols) but it MUST contain at least 1 of each lowercase, uppercase and numeric.

And once again it churned away for a bit and threw out some code, it once again looked sensible, so I ran it.

And this time, it only partially worked, I got errors from the code[^6].

It looked like it was *trying* to do what I asked but was failing, I looked a bit more at the code, expecting this to convince me that LLMs were still bad at this. But all the flags behaved as expected, all the logic *looked* right. I couldn't see anywhere that it was going wrong.

So I told it as much:

> This appears to be working and the code looks good, but the passwords are not changing:
> `Update call succeeded but no changes reported by NetBox for payload`
> Is the code doing something wrong, is there a change we can make to fix it?

At this point it started talking a bit about how some APIs don't allow you to set passwords in certain ways and suggested we might need to use special API calls for that and a whole bunch of overly verbose thoughts on this. It even found an [old netbox bug report](https://github.com/netbox-community/netbox/issues/14339) about password changing not working via the API at all (though we're using a much later version so that bug did not apply) but it did also then come up with some recommendations:

{{< postimage src="GeminiDebugging1.png" side="middle" alt="Gemini debugging some Code" >}}

At this point I was a bit impressed, it gave me a pretty sensible suggestion that I would have tried myself as a way to rule out where the fault lies. I tried it, it worked.

I won't bore you with the rest of the details - but suffice to say that with a bit more prompting and debugging "we" managed to figure out that there was [a bug in pynetbox](https://github.com/netbox-community/pynetbox/issues/694) with changing-passwords and "we" were able to work around it by using http calls directly for that action and pynetbox for everything else.

A job fairly well done. If it wasn't for the library bug I'd have been done with this with 2 prompts, and no more than 5-10 minutes of time. Dealing with the library bug made it take longer, but ultimately I'd have had to do that anyway and it would have taken me even longer manually.

This single interaction has placed AI Coding agents into the "Useful for small tasks I can't be bothered with myself, that probably don't deserve too much time investment from my side".

Armed with this success, I installed the Gemini extension into VSCode and attempted to use it to solve a long-standing issue I hadn't got round to solving for [MyDNSHost](https://mydnshost.co.uk/). I have some stats pages that generate graphs using the Google Charts API, sometimes there are too many items being graphed that the charts are less useful than they could be, and I'd like to be able to toggle them on/off.

I believe this functionality is built-in with chart.js but not with google charts which I had chosen long ago. So I asked Gemini to take a look at the code I already had, and add this feature.

This was a bit more complicated an ask for it. This time it involved a lot more hand-holding and pointing it in the right direction, and also stopping it hallucinating things that didn't exist in the API[^7]. At one point I had to just do some bits myself and tell it I'd done them. But it did eventually come up with most of the changes needed and get me the functionality I wanted.

So this interaction didn't change my opinion too much on the state of AI for coding. It's still "ok, but not great". Also, using Gemini within VSCode felt a bit clunky, it suggested that I had to specifically give it files to include in the context window and then ask it to do things with them. This didn't seem particularly good for a large project where some things may be spread over many files. Don't get me wrong, it was still better than using the web-ui, but still *felt meh*. Though having used it a bit more since, this may be unfair as in later tests it was able to find context itself, so I probably owe it another test now that I am more familiar with AI-coding tools[^8].

Despite my mixed feelings from my interactions with Gemini, I have continued to make use of LLMs for some (small, not mission-critical) coding tasks. Much like Chris, I too have paid Anthropic [a lot of money](https://www.anthropic.com/pricing)[^9] to get access to Claude Code and have had some very pleasant experiences with it. It's nice and easy to use (even the VSCode integration is pretty much "Here is our console app, inside your IDE but now we'll use the IDE to do diffs not the console"). If you give it good prompts, it will generally do what you asked of it.

And overall, I share much of the same sentiments as Chris does[^10]:

> What did impress me, though, was its ability to churn out reasonable-ish code. It can hack together a bash script as well as I can, and do it far faster than I’d be able to. Sometimes they even work.
>
> ...
>
> It’s like having a keen but not particularly thorough Junior Engineer at your beck and call. If you give it a clearly defined task and guidance on how to implement it (and maybe some feedback as it suggests changes), it’s more than capable of doing it.
>
> - Chris Smith, May 28, 2025, [chameth.com](https://chameth.com/coming-around-on-llms/)

Also like Chris[^11] I have a lot of side-projects, or hobby projects, or just "This might be fun?" projects. A lot of the time, these get to a point where I can't be bothered with something so I just leave it, or work around it, or ignore it. Having something like Gemini or Claude that I can just say "hey, can you implement this for me?" and watching it go away and do it is quite nice.

It's also *really* good for "I want an MVP of an idea". One evening I spent a few hours implementing an idea quickly by hand to test something, but wasn't entirely happy with it for various reasons. So the next day (on a train over ssh no less) I asked claude to do the same thing, and it had the same working idea as me but considerably quicker (and prettier looking), and I was able to iterate on it much quicker and add more features to the MVP in half the time and ended up overall being happier with what it came up with.

Something that is important though, is that coding for me is brain-exercise and also relaxation. I do it for fun as much as anything else and can easily and happily lose hours coding something interesting. So I'm glad that I also still get a lot of satisfaction from prompting claude to code something and coming up with the plan and ideas and telling it what to do and how I want it to work etc. Sometimes this is at a higher level, sometimes a much lower more-specific level. It handles both with varying levels of success. I know I can write all the code myself, but using AI this way lets me do it *quicker*, and I can still go in afterwards (or mid-session) and fix things I don't like or want done differently.

There's still a lot of cases where I won't want to just throw an LLM at a problem. Complex code, or cases where I need to properly control or understand everything that is happening. Or things that are a bit more mission-critical. But for personal projects? Hobby Projects? "Is-this-worth-putting-any-time-into" quick-prototype projects? Absolutely! It's not replacing me entirely any time soon, and it's definitely over-hyped - but it's working well for me and I honestly feel like I'm getting value from my subscription. (Maybe not as much value as it costs, but certainly some non-0 amount of value)


[^1]: The fact it relies a lot on the non-consensual scraping of code, images, the internet, blog posts, etc. The constant stream of bots everywhere just spewing out AI-generated slop. The fact that it's overall reducing the quality of information available on the internet because no one needs to post to StackOverflow anymore they can just ask ChatGPT. But without people doing that, the training data is going to be compromised. There will be more AI-Generated code in the training data rather than (maybe) higher-quality human-generated code.
[^2]: This reminds me of [another post](https://chameth.com/if-all-you-have-is-a-hammer/) from Chris that mentions "[Gell-Mann amnesia](https://en.wikipedia.org/wiki/Gell-Mann_amnesia_effect)" and this wikipedia article then mentions the concept of "[Falsus in uno, falsus in omnibus](https://en.wikipedia.org/wiki/Falsus_in_uno,_falsus_in_omnibus)" - the combination of these is somewhat how I feel about trusting ChatGPT et al for anything.
[^3]: Technically, a friend generated the images of me with my consent as I didn't have a suitable graphics card to do it at the time
[^4]: Chris has also [done the same](https://chameth.com/infinite-avatars/) thing, but in a much more interesting way.
[^5]: I know, I'm [too polite](https://techcrunch.com/2025/04/20/your-politeness-could-be-costly-for-openai/) to the AI agents. But I don't want them to go all terminator on me. I plan to be spared in the great AI uprising.
[^6]: From the error-handling in the code, not from the code itself.
[^7]: This amused me, given that it's Google's AI, writing code for Google's product. And it still gets it wrong.
[^8]: I never got the same clunky-feeling from claude-code. But this could be any number of reasons, such as "I like doing things in a terminal window".
[^9]: At the time of writing, £90/month for the "Max 5x" plan
[^10]: If you didn't read [his post](https://chameth.com/coming-around-on-llms/) when I linked it earlier, please do, I even linked it again for you just there to make it easier!
[^11]: How many times can I say Chris in this post? (8, including the footnotes).
