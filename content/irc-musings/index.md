---
title: IRC Musings
author: Dataforce
type: page
date: 2012-09-03T02:06:40+00:00

---
<span id="top"></span>

## Contents

  * [DMDirc](#dmdirc)
  * [DFBnc](#dfbnc)
  * [My "Listmode" Proposal](#listmode)
  * [My "Timestamped IRC" Proposal](#timestamping)

<span id="dmdirc"></span>

## DMDirc

I am one of the developers for an IRC Client called [DMDirc](http://www.dmdirc.com) (More information can be found on the site).

I'm primarily in charge of the actual IRC Parser, and the plugin system however I have also developed some of the other plugins such as the DCC Plugin.

<a href="#top" style="font-size: small">Back to top</a>

<span id="dfbnc"></span>

## DFBnc

I also develop an IRC "Bouncer" called [DFBnc](http://dfbnc.com/) which is based around the DMDirc IRCParser.

The combination of these 2 applications has contributed to the ideas of these proposals.

<a href="#top" style="font-size: small">Back to top</a>

<span id="listmode"></span>

## IRC List Modes

Whilst developing the parser for DMDirc I noticed that the current way listmodes work is rather flawed, At the moment there is no usable standard for getting the current listmodes of a channel on an irc network.

Each ircd uses its own list modes, and numerics for giving the information, there is no easy way to be able to parse these lists reliably without checking EVERY ircd to see what numerics it uses, and even that isn't enough.

Take for example freenode's hyperion IRCD, and the following commands:

```
MODE #Channel +d %moded!user@host
MODE #Channel +d moded!user@host
MODE #Channel +q modeq!user@host
MODE #Channel +b modeb!user@host
```

This will:

* set a ban on a user with the host "modeb!user@host"
* silence a user with the host "modeq!user@host"
* ban anyone with a realname of "%moded!user@host"
* ban anyone with a realname of "moded!user@host"

Seems easy enough? - if you are in the channel at the time the mode is set, you can easily see what mode it is (b, q, d). However a new client joining doesn't see this, instead they issue the following command:

```
MODE #Channel bqd
```

to which they get the following response back:

```
:pratchett.freenode.net 367 DFTest #Channel modeb!user@host DFTest!i=shane@dataforce.org.uk 1173715309
:pratchett.freenode.net 367 DFTest #Channel %modeq!user@host DFTest!i=shane@dataforce.org.uk 1173715309
:pratchett.freenode.net 368 DFTest #Channel :End of Channel Ban List
:pratchett.freenode.net 367 DFTest #Channel moded!user@host DFTest!i=shane@dataforce.org.uk 1173715309
:pratchett.freenode.net 367 DFTest #Channel %moded!user@host DFTest!i=shane@dataforce.org.uk 1173715309
:pratchett.freenode.net 368 DFTest #Channel :End of Channel Ban List
```

There is no easy way to know which were set as mode d, and which were mode b as they come from the same numeric. (Of course you could statefully remember which modes you asked for in which order - but on dancer/hyperion using "bdq" not "bqd" returns the exact same - q and b are merged into one, which would still require some hard-coded knowledge. There is also still the problem that not all IRCDs use the same numeric for everthing)

_RPL_ISUPPORT_ allows IRC parser/client developers to dynamically discover what modes are available on the IRCD, yet the raw numerics for each type of list mode _still_ need to be hardcoded.

### My Proposal

To aid in the design of IRC Parsers, I propose an addition to _RPL_ISUPPORT_ and a new command.

The addition to _RPL_ISUPPORT_ is a "LISTMODE=997" option.

This new option would let clients know that there is an easy-to-parse/sensible way to get the current list modes on a channel, the "LISTMODE" command. (ie /LISTMODE #Channel bdq or (/LISTMODE #Channel * for all list modes))

The LISTMODE commands given above would return the following:

```
:pratchett.freenode.net 997 DFTest #Channel b modeb!user@host DFTest!i=shane@dataforce.org.uk 1173715309
:pratchett.freenode.net 997 DFTest #Channel d %moded!user@host DFTest!i=shane@dataforce.org.uk 1173715309
:pratchett.freenode.net 997 DFTest #Channel d moded!user@host DFTest!i=shane@dataforce.org.uk 1173715309
:pratchett.freenode.net 997 DFTest #Channel q %modeq!user@host DFTest!i=shane@dataforce.org.uk 1173715309
:pratchett.freenode.net 998 DFTest #Channel :End of Channel List Modes
```

The numeric used for the individual items is the same as specified in _RPL_ISUPPORT_ (in this case 997) and the "End of list modes" uses LISTMODE+1 for its numeric. This allows ircds to use what ever numeric they want that is free - without clients needing to know what numeric each IRCD uses in advance.

The addition of the /LISTMODE command and not just altering the current /MODE command is to maintain backwards compatability with older clients.

### Error Handling

Error handling is similar to that for the traditional /MODE request:

* If a client requests modes for a channel they are not on, ERR_NOTONCHANNEL (Numeric 442) should be returned
* If a client requests a mode that is not a list mode or not a mode at all, then ERR_UNKNOWNMODE (Numeric 472) should be given for each invalid mode.
* If a client requests a mode that they do not have access to see (eg +e or +I on Hybrid-based ircds) then ERR_CHANOPRIVSNEEDED (Numeric 482) should be returned.

If a request for "*" is given, then the only error permitted is ERR_NOTONCHANNEL.

### Existing list mode information

To the best of my knowledge, the information [on the dmdirc wiki](http://wiki.dmdirc.com/protocol:listmodes) provides a complete list of current numerics used by various IRCDs, and is what the DMDirc parser uses for parsing list modes

### Known Implementations

At the moment as far as I am aware the only IRC Client/Parser that understands the LISTMODE option/command is [DMDirc](http://dmdirc.com/) (however [smuxi](http://smuxi.org) appears to be [considering it](http://projects.qnetp.net/issues/show/229), and the only server that allows its use is [WeIRCd](http://eloxoph.com/weircd/) (<irc://irc.eloxoph.com/>) and the only "bouncer" that allows its use is [DFBnc-Java](http://dfbnc.com/).

### Questions, Comments, Corrections

Any questions about this should be sent to <IRCDevel@Dataforce.org.uk>, or contact Dataforce in #DMDirc on [Quakenet](irc://irc.quakenet.org/dmdirc) or [Freenode](irc://irc.freenode.net/dmdirc)

### Changelog

  * 2009-11-25 - Added Error Handling.

<a href="#top" style="font-size: small">Back to top</a>

<span id="timestamping"></span>

## Timestamped IRC

Unlike the previous proposal, this one is much less generic and has a somewhat specific use case, but nevertheless seems useful enough to implement and document.

When a user reconnects to a bouncer, they often do so either in the midst of ongoing conversations or during a periods of downtime for channels. In the first case, the user may need to wait a while before jumping in, and in the latter case the user probably won't even know.

Often the solution to the first case is to provide a "backbuffer" of conversation, the last X lines or so. This can be replayed as a series of notices (which then looks out of place) or as a series of **PRIVMSG**s as they arrived to the BNC. Both of these work well for the first case, but often provide no hint about _when_ these occured, unless a timestamp is hacked into the line either at the start or end which again looks out of place.

### My Proposal

Therefore, a possible solution to both is to provide a timestamp _alongside_ the replayed **PRIVMSG**, and allow the IRC Client to display this however it sees fit.

As before, I propose an addition to _RPL_ISUPPORT_ and a new command.

The addition to _RPL_ISUPPORT_ is a "TIMESTAMPEDIRC" option.

This new option would let clients know that the servers supports TimestampedIRC. The client could then enable it with a "TIMESTAMPEDIRC" command. (ie /TIMESTAMPEDIRC ON)

Once enabled, certain types of messages can include timestamp data. My suggestion is to add this at the very beginning of the line, as follows:

```
@1316145182038@:Dataforce!Shane@dataforce.org.uk PRIVMSG #DMDirc :Test Message
```

Clients can then check for the presence of '@' at the start of the line to see if a timestamp has been included, and then they can find the end of it with the next '@' symbol, anything beyond then should be parsed as normal. It is important to note that IRC lines must still remain under 512 characters long, even with the timestamp prepended to the start.

The timestamp is based on the java's `System.currentTimeMillis()`, so where milliseconds are unsupported, timestamps should be multiplied or divided by 1000 as appropriate.

It is suggested that not every line be timestamped to cut down on processing time, only those where it makes sense. Clients that understand timestamping are free to ignore any timestamps they see fit, as the timestamp is only a suggestion.

### Timezones and clock skew

Obviously, not all servers are in perfect sync with each other time wise, different timezones, or skewed clock. This has been taken into consideration.

Once a client has signalled their desire to start using timestamps with `/TIMESTAMPEDIRC` or `/TIMESTAMPEDIRC ON`, the server responds with something like:

```
:my.server.name TSIRC 1 1316146177387 :Timestamped IRC Enabled
```

The parameter of note here is the 4th parameter, this is the current time on the server and can be used by the client to determin the difference between timestamps which it can then use when processing any timestamped messages.

Currently, the 3rd parameter is "1" if TimestampedIRC has been enabled, or "0" if it was disabled (`/TIMESTAMPEDIRC OFF`). A server can (if it so wishes) refuse to enable TimestampedIRC by always setting this to 0.

### Known Implementations

At the moment as far as I am aware the only IRC Client/Parser that understands the TIMESTAMPEDIRC option/command is [DMDirc](https://dmdirc.com/), no servers currently support it, and the only "bouncer" that allows its use is [DFBnc-Java](https://dfbnc.com/).

### Questions, Comments, Corrections

Any questions about this should be sent to <Dataforce@Dataforce.org.uk>, or contact Dataforce in #DMDirc on [Quakenet](irc://irc.quakenet.org/dmdirc) or [Freenode](irc://irc.freenode.net/dmdirc)

### Changelog

  * 2011-10-16 - First draft.

<a href="#top" style="font-size: small">Back to top</a>
