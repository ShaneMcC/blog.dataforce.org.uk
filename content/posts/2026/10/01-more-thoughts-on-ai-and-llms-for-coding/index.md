---
title: "More Thoughts on AI and LLMs for Coding"
author: Dataforce
url: /2026/10/more-thoughts-on-ai-and-llms-for-coding/
image: postimg.png
type: post
date: 2026-10-01T12:40:00Z
category:
  - General
  - Code
  - AI
---

Slightly[^1] over a year ago I [previously posted](https://blog.dataforce.org.uk/2025/06/thoughts-on-ai-and-llms-for-coding/) some thoughts on AI and LLMs. And due to the amazing frequency[^2] with which I make new posts, it has been my most recent post for a while. And I think it deserves an update.

When that post was made:
 - Opus 4 was the best of the Claude models
 - Claude-Code had only been GA for about a month.
 - OpenAI were also in their 4 series, GPT-4o, GPT-4.1 and o3/o4-mini.
 - Codex CLI had also only existed for a couple of months
 - Google Gemini was on the 2.5 series

I think my initial feelings were fair and accurate for these models. In addition, Opus was more-expensive to use, so I was more likely to be using Sonnet for things unless I thought it really needed something.

As mentioned in that post, I had a new-and-fresh claude-code subscription[^3]. I had only intended to have it for a couple of months... Turns out I've never stopped paying for it, and have been using it for various levels of things since.

It's crazy how fast the state of this has all changed, and how much my use and experience has changed...

The TL;DR here is that I am no longer sitting close to "Hype" and I now sit much closer to "Incredibly useful Tool", but read on for a more fleshed out version of this!

<!--more-->

A few months after that post, in November, Opus 4.5 was released and this massively improved things, Claude became "good". Then came Opus 4.6 with 1M context in February of this year.

I don't even remember now when the switch for me happened, probably around about March this year, but [similarly to Chris](https://chameth.com/the-expanding-scope-of-coding-agents/) I've seen my scope of usage change. A lot.

In that previous post I said this:
> all my experience to date was very firmly at the level of “Meh, It’s ‘ok’. Not good. Certainly not a tool I expect to use all day every day”.

and this:
> There’s still a lot of cases where I won’t want to just throw an LLM at a problem. Complex code, or cases where I need to properly control or understand everything that is happening. Or things that are a bit more mission-critical. But for personal projects? Hobby Projects? “Is-this-worth-putting-any-time-into” quick-prototype projects? Absolutely! It’s not replacing me entirely any time soon, and it’s definitely over-hyped - but it’s working well for me

And these days, neither of those is quite correct.

I now use claude code **almost every day**[^4]. It's very unlikely for me to have a VSCode window[^5] open without it also having a few claude code tabs[^6] open as well.

And the modern models[^7] are *really good*. So I actively use it for actual "real" personal projects and work projects.

Claude writes most of my code these days. The difference between project types is more about my level of prompting and plan-review than anything else.

I spend a lot of time in plan mode in claude code, I often give it reasonably large prompts that have *most* of a requirement fleshed out with what I want, approximately how I want things and what I think I'd do. I then iterate over this with Claude. It suggests things, I push back, I ask it questions (why are we doing something a certain way, could it be done a different way etc). And then once we're done... I let it go off and do it.

At first, I used to keep it in full-manual mode, I had to approve every file edit. Then I moved to mostly "allow-all-writes", and these days, I mostly run it in "auto" mode once we're done with the plan. (This allows it to do a lot of the post-code testing itself, which it tends to do a lot of)

Over the past year I've seen my usage move through:

- Prompt it to fix a few lines or answer some questions, doing most code myself
- Ask it to write small functions I'm too lazy with
- Prototype some ideas I don't really care about writing from scratch myself
- Implement slightly larger functions, carefully watched, with line-by-line review and many corrections
- Whole classes, still mostly reviewed but less corrections
- Whole applications, reviewing the overall approach and criticising the deliverable (ie the web page, the work flow) rather than any of the code.

That's not to say I don't still look at some of the code, but less and less. Some more mission-critical code I may look more at.

As I've progressed down this list, I've updated a lot of our work tooling for monitoring and automation and written new tools for automating some internal processes that were previously very manual. Things that were "it would be nice to have this automated" but not always worth the time investment to actually do that by hand - because that investment time is now reduced.

For my own projects: In [MyDNSHost](https://mydnshost.co.uk/) I've used it to add some additional admin-related 2FA security, analyse some failures, used it to handle a BIND upgrade I was dreading (because it completely changed how DNSSEC Auto-Signing worked), rewrote a lot of my task-management UI, rewrote all of my graphs (Moved from google charts to d3) among other things. In other applications I've even added MCP support and "talk to an agent" code (that uses the MCP for the available tools), and AI-Assisted image-processing. I'm sure I'll talk more about some of these in a future post[^8].

This is all a far cry from "It generates Proof-of-concepts", it now generates real, day-to-day useful "mission-critical" code.

Claude is also way better than I am at UI/UX. Even going back to older projects where I don't need it to change the code much, modernising the UI a bit makes them look and feel so much better to use.

I also find myself using claude (non-code) a bit more for debugging sessions - It's quite good at looking at a lot of logs/data and analysing it and helping confirm/deny thoughts. These tend to be more collaborative in nature. I tell it my thoughts, I give it logs, I see what it thinks, and it helps refine and augment my thinking. I don't use it as the exclusive debugger.

It hasn't all been cake and rainbows though.

Sometimes, Claude can be infuriating to work with.

Opus 5 was so bad at *communicating* that I hated working with it. I'd have to constantly ask it to explain things in a less-awful way, or I'd fall back to Fable or Opus 4.8 (5.5 is, thankfully, much better at this and I'm finding this to be a happy-path again). Sometimes it still doesn't *quite* do what I want and needs telling off, but this is getting to be less and less.

I generally dislike entirely-AI-generated PR descriptions for projects. I make an exception for PRs from-myself-to-myself that I mostly raise as a reference for "this was all of the commits of a single big feature". But generally, I still think humans should talk to humans to be able to explain what/why (even if the *exact* how is no longer as well-known as it was in the past). AI can help with this, and give some of the technical details. But I like a human voice somewhere.

I also dislike that almost everything I read now is obviously written by AI. I like reading human-written text. I think blog posts (like this one) should be written by a person (like this one!), with their own voice, not an AI. I think having an AI fact-check it, proof-read it, etc is fine. (I did that here. Claude gave me a table of "what models were available in June last year", and pointed out some minor corrections. I wrote all the text.)

While I find Google Gemini can be useful for helping me cook[^9] - I don't end up enjoying the AI-Search results in Google. They still have too many "wrong" bits. Since the last post, I've not really used Gemini for any more code-related tasks as Claude is just much better suited to it.

So yeah... my overall stance has changed. This isn't just hype. LLMs are absolutely a force-multiplier for development. How good that force is probably depends on who is prompting and supervising. The Slop-Cannon is real if not managed correctly.

In my last post I said I still found prompting-claude to be as fun as writing code myself, that bit hasn't changed and is still true - So much so that I've had to add custom hooks into claude-code to make it refuse to do anything for me after 2am otherwise I easily find myself still awake at 5am doing things - I'm definitely getting my money's worth now.

Some of the ethical concerns I raised previously haven't changed. And Humans will still make things worse by being bad. I still worry for junior engineers, who won't end up with the same intrinsic knowledge of things and be able to debug things on their own, or they won't have the domain-knowledge to be able to prompt the AIs effectively to get the same quality of results that I am getting. I weep for the price and availability of RAM and Storage as all the supply is used up by AI demand.

Overall, I think this is here to stay[^10].


[^1]: Maybe a bit more than slightly...
[^2]: I keep *wanting* to... I just... don't.
[^3]: Looks like I've been a Max 5x subscriber since May 2025, So I've been along for the whole ride.
[^4]: I originally said "every day" here, but during proof-reading, claude pulled up my actual usage stats and told me off because this wasn't quite true. Sometimes I have days where I am travelling and don't use it... (Apparently 182 active days out of 246 if you care)
[^5]: I still at least use an IDE!
[^6]: I *really* like using claude code inside VSCode, I find it a really nice and pleasant experience. I probably don't need to do it inside an IDE anymore, but I like it.
[^7]: As of this post, GPT-6 and Opus 5.5 etc. Opus 5.5 is my main "daily-driver"
[^8]: At least I'll try to. I'll add it to the post backlog that I never get through!
[^9]: I started cooking this year! Gemini helps me decide what to cook based on what I have in, and what I don't want (Onions. No Onions. Ever.)
[^10]: For Now. Until the AI-Overlords (OpenAI, Anthropic) pull the plug and leave us all completely screwed.
