---
title: Email Woes
author: Dataforce
type: post
date: 2007-08-18T01:10:19+00:00
url: /2007/08/Email-Woes/
category:
  - Code
  - General
  - IRC

---
On a daily basis, I get around 800 emails to my email accounts, of which most of it is spam.

Now as good as thunderbird is at detecting spam, even it fails at a lot of the spam I receive, leaving me with around 100-200 spam per day that gets into my inbox.

I've dealt with and accepted this for over a year now, before a discussion on IRC made me decide to do something about it. (When I say discussion, I mean [Chris](http://www.md87.co.uk) pasted one line showing how good the [UTD-Hosting](http://utd-hosting.com) mail server was at preventing junk getting to him)

So, I recently (Today and yesterday) started prodding my postfix config to help with the problem.

Firstly I added some RBL checking, this was easy enough, 3 lines to my config in the smtpd\_recipient\_restrictions bit:

```
    reject_rbl_client list.dsbl.org
    reject_rbl_client zen.spamhaus.org
    reject_rbl_client dnsbl.sorbs.net
```

I also added:

```
    reject_non_fqdn_recipient
    reject_unknown_recipient_domain
```

I also added the following lines:

```
smtpd_helo_required = yes

smtpd_delay_reject = yes

smtpd_helo_restrictions =
    permit_mynetworks
    check_helo_access hash:/etc/postfix/helo_access
    reject_non_fqdn_hostname
    reject_invalid_hostname
    permit

smtpd_sender_restrictions =
    permit_mynetworks
    reject_non_fqdn_sender
    reject_unknown_sender_domain
    permit
```

/etc/postfix/helo_access looks like this (Its surprising how many mails this catches, 114/7500 - altho they would probably be caught later on):

```
soren.co.uk            REJECT You are not me.
207.150.170.50         REJECT You are not me.
```

Next step was SPF checking, this involved adding to smtpd\_recipient\_restrictions:

```
check_policy_service unix:private/policy
```

and to master.cf

```
policy  unix  -       n       n       -       -       spawn
        user=nobody argv=/usr/bin/perl /usr/lib/postfix/policyd-spf-perl
```

(One can apt-get install postfix-policyd-spf-perl or download it from http://www.openspf.org/Software)

Currently I use catch-all on all my domains (yes this is stupid I know) and as a result, I get a lot of spam to 1) Addresses that don't exist and never have 2) Addresses that used to exist for others but now don't.

To combat this, I added this line to smtpd\_recipient\_restrictions:

```
check_recipient_access hash:/etc/postfix/recipient_access
```

/etc/postfix/recipient_access looks something like this:

```
foo@example.com REJECT This account is no longer valid.
bar@example.com REJECT This account is no longer valid.
baz@example.net REJECT This account is no longer valid.
```

The result of all this can be seen by running the mailstats script [Chris](http://www.md87.co.uk) was kind enough to share with me:

```shell
root@soren:/etc/postfix# ./mailstats.php

Incoming --(7500)--> Valid HELO --(6707)--> Valid Sender --(6705)--> Passed by dsbl --(6136)--> Passed by spamhaus --(811)--> Passed by sorbs --(568)--> Passed by relay check --(565)--> Passed by SPF --(542)--> Forwarded to shinobu --(390)--> To a valid domain --(339)--> To a valid user --(306)--> Dropped Spam --(306)--> Delivered.
Total Rejections: 7194 (Unknown Reason: 0 | Pretended to be me: 114)
```

The "Forwarded to shinobu" entry is a server for which I am the backup MX for, this accounts for 152 mails (about 2%)

The delivered count of 306 mails is about 4%, meaning that 94% of all the junk mail I receive is now dropped by postfix and not delivered to my mailbox!

These simple additions have made a huge difference! I have a 10 day holiday coming up, and now rather than coming home to 8000 mails, I'll only come home to 320!

As a further line of defence, prior to being sent to my mailbox, those 4% of mails get filtered through spamassassin (which I have configured to only run for certain domains, with different scores for different domains/users as needed) which does a good job of catching the spam that thunderbird misses, configuring a mail filter on thunderbird to filter these mails (Which get subject tagged with {Spam?}) into my junk folder (as well as configuring thunderbird to trust what the spamassassin headers say) means very little, if any, spam now reaches my inbox!

Brilliant!
