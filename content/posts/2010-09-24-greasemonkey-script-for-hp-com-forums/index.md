---
title: Greasemonkey script for hp.com forums
author: Dataforce
type: post
date: 2010-09-24T12:23:51+00:00
url: /2010/09/greasemonkey-script-for-hp-com-forums/
category:
  - General

---
If you've ever visited the hp.com forums you'll know that any links in the post get enclosed by a call to "javascript:openExternal('')" in the href rather than doing it properly in onClick. Amongst other things, this breaks the ability to middle click to open links in new tabs.

This finally annoyed me enough today and as a result, I now use the following greasemonkey script:

{{< prettify javascript >}}
// ==UserScript==
// @name           Stupid HP.COM Links
// @namespace      http://shanemcc.co.uk/
// @include        *hp.com*
// ==/UserScript==

var a = document.getElementsByTagName("A");
for (var i = 0; i &lt; a.length; i++){
	var href = a[i].href;
	href = href.replace(/javascript:openExternal\('([^']+)'\)/i, '$1');

	a[i].href = href;
}
{{< /prettify >}}

This will make the links no longer have the call to openExternal around them, and thus make them middle-click friendly.
