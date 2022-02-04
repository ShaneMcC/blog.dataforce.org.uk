---
title: "DNS Hosting - Part 2: The rewrite"
author: Dataforce
url:  /2018/01/dns-hosting-part-2/
image: dns.png
description: Creating MyDNSHost
type: post
date: 2018-01-20T17:25:32Z
category:
  - General
  - DNS
  - Code
---

In my [previous post about DNS Hosting](/2018/01/dns-hosting-part-1/) I discussed the history leading up to when I decided I needed a better personal DNS hosting solution. I decided to code one myself to replace what I had been using previously.

I decided there was a few things that were needed:

  * Fully-Featured API
    * I wanted full control over the zone data programmatically, everything should be possible via the API.
    * The API should be fully documented.
  * Fully-Featured default web interface.
    * There should be a web interface that fully implements the API. Just because there is an API shouldn't mean it *has* to be used to get full functionality.
    * There should exist nothing that only the default web ui can do that can't be done via the API as well.
  * Multi-User support
    * I also host some DNS for people who aren't me, they should be able to manage their own DNS.
  * Domains should be shareable between from users
    * Every user should be able to have their own account
    * User accounts should be able to be granted access to domains that they need to be able to access
      * Different users should have different access levels:
        * Some just need to see the zone data
        * Some need to be able to edit it
        * Some need to be able to grant other users access
  * Backend Agnostic
    * The authoritative data for the zones should be stored independently from the software used to serve it to allow changing it easily in future

These were the basic criteria and what I started off with when I designed [MyDNSHost](https://mydnshost.co.uk).

<!--more-->

{{< postimage src="homepage_300.png" large="homepage.png" side="left" alt="MyDNSHost Homepage" >}}

Now that I had the basic criteria, I started off by coming up with a basic database structure for storing the data that I thought would suit my plans, and a basic framework for the API backend so that I could start creating some initial API endpoints. With this in place I was able to create the database structure, and pre-seed it with some test data. This would allow me to test the API as I created it.

I use chrome, so for testing the API I use the [Restlet Client](https://chrome.google.com/webstore/detail/restlet-client-rest-api-t/aejoelaoggembcahagimdiliamlcdmfm?hl=en) extension.

Armed with a database structure, a basic API framework, and some test data - I was ready to code!

Except I wasn't.

Before I could start properly coding the API I needed to think of what endpoints I wanted, and how the interactions would work. I wanted the API to make sense, so wanted to get this all planned first so that I knew what I was aiming for.

I decided pretty early on that I was going to version the API - that way if I messed it all up I could re do it and not need to worry about backwards compatability, so for the time being, everything would exist under the `/1.0/` directory. I came up with the following basic idea for endpoints:

{{< postimage src="loggedin_300.png" large="loggedin.png" side="right" alt="MyDNSHost LoggedIn Homepage" >}}

 * **Domains**
   * `GET /domains` - List domains the current user has access to
   * `GET /domains/<domain>` - Get information about <domain>
   * `POST /domains/<domain>` - Update domain <domain>
   * `DELETE /domains/<domain>` - Delete domain <domain>
   * `GET /domains/<domain>/records` - Get records for <domain>
   * `POST /domains/<domain>/records` - Update records for <domain>
   * `DELETE /domains/<domain>/records` - Delete records for <domain>
   * `GET /domains/<domain>/records/<recordid>` - Get specific record <recordid> for <domain>
   * `POST /domains/<domain>/records/<recordid>` - Update specific record <recordid> for <domain>
   * `DELETE /domains/<domain>/records/<recordid>` - Delete specific record <recordid> for <domain>
 * **Users**
   * `GET /users` - Get a list of users (non-admin users should only see themselves)
   * `GET /users/(<userid>|self)` - Get information about a specific user (or the current user)
   * `POST /users/(<userid>|self)` - Update information about a specific user (or the current user)
   * `DELETE /users/<userid>` - Delete a specific user (or the current user)
   * `GET /users/(<userid>|self)/domains` - Get a list of domains for the given user (or the current user)
 * **General**
   * `GET /ping` - Check that the API is responding
   * `GET /version` - Get version info for the API
   * `GET /userdata` - Get information about the current login (user, access-level, etc)

This looked sane so I set about with the actual coding!

Rather than messing around with oauth tokens and the like I decided that every request to the API should be authenticated. Initially using basic-auth and username/password, but eventually also using API Keys, this made things fairly simple whilst testing, and made interacting with the API via scripts quite straight forward (no need to grab a token first and then do things).

The initial implementation of the API with domain/user editing functionality and API Key support was completed within a day, and then followed a week of evenings tweaking and adding functionality that would be needed later - such as internal "hook" points for when certain actions happened (changing records etc) so that I could add code to actually push these changes to a DNS Server. As I was developing the API, I also made sure to document it using [API Blueprint](https://apiblueprint.org/) and [Aglio](https://github.com/danielgtaylor/aglio) - it was easier to keep it up to date as I went, than to write it all after-the-fact.

Once I was happy with the basic API functionality and knew from my (manual) testing that it functioned as desired, I set about on the Web UI. I knew I was going to use [Bootstrap](https://getbootstrap.com) for this because I am very much not a UI person and bootstrap helps make my stuff look less awful.

{{< postimage src="records_300.png" large="records.png" side="left" alt="MyDNSHost Records View" >}}

Now, I should point out here, I'm not a developer for my day job, most of what I write I write for myself to "scratch an itch" so to speak. I don't keep up with all the latest frameworks and best practices and all that. I only recently in the last year switched away from hand-managing project dependencies in Java to using gradle and letting it do it for me.

So for the web UI I decided to experiment and try and do things "properly". I decided to use [composer](https://getcomposer.org) for dependency management for the first time and then used a 3rd party request-router [Bramus/Router](https://github.com/bramus/router) for handling how pages are loaded and used [Twig](https://twig.symfony.com) for templating. (At this point, the API code was all hand-coded with no 3rd party dependencies. However my experiment with the front end was successful and the API Code has since changed to also make use of composer and some 3rd party dependencies for some functionality.)

The UI was much quicker to get to an initial usable state - as all the heavy lifting was already handled by the backend API code, the UI just had to display this nicely.

I then spent a few more evenings and weekends fleshing things out a bit more, and adding in things that I'd missed in my initial design and implementations. I also wrote some of the internal "hooks" that were needed to make the API able to interact with BIND and PowerDNS for actually serving DNS Data.

As this went on, whilst the API Layout I planned stayed mostly static except with a bunch more routes added, I did end up revisiting some of my initial decisions:

 * I moved from a level-based user-access to the system for separating users and admins, to an entirely role-based system.
   * Different users can be granted access to do different things (eg manage users, impersonate users, manage all domains, create domains, etc)
 * I made domains entirely user-agnostic
   * Initially each domain had an "owner" user, but this was changed so that ownership over a domain is treated the same as any other level of access on the domain.
   * This means that domains can technically be owned by multiple people (Though in normal practice an "owner" can't add another user as an "owner" - only users with "Manage all domains" permission can add users at the "owner" level)
   * This also allows domain-level API Keys that can be used to only make changes to a certain domain not all domains a user has access to.

Eventually I had a UI and API system that seemed to do what I needed and I could look at actually putting this live and starting to use it (which I'll talk about in the next post).

After the system went live I also added a few more features that were requested by users that weren't part of my initial requirements, such as:

 * TOTP 2FA Support
   * With "remember this device" option rather than needing to enter a code every time you log in.
 * DNSSEC Support
 * EMAIL Notifications when certain important actions occur
   * User API Key added/changed
   * User 2FA Key added/changed
 * WebHooks when ever zone data is changed
 * Ability to use your own servers for hosting the zone data not mine
    * The live system automatically allows AXFR for a zone from any server listed as an NS on the domain and sends appropriate notifies.
 * Domain Statistics (such as queries per server, per record type, per domain etc)
 * IDN Support
 * Ability to import and export raw BIND data.
   * This makes it easier for people to move to/from the system without needing any interaction with admin users or needing to write any code to deal with zone files.
   * Ability to import Cloudflare-style zone exports.
     * These look like BIND zone files, but are slightly invalid, this lets users just import from cloudflare without needing to manually fix up the zones.
 * Support for "Exotic" record types: CAA, SSHFP, TLSA etc.
 * Don't allow domains to be added to accounts if they are sub-domains of an already-known about domain.
   * As a result of this, also don't allow people to add obviously-invalid domains or whole TLDs etc.
