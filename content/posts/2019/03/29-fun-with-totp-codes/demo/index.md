---
title: "Fun with TOTP Codes Demo"
author: Dataforce
url:  /2019/03/fun-with-totp-codes/demo/
type: lowerpage
date: 2019-03-29T04:20:00Z
---

[Back to post]({{< ref "post/index.md" >}})
{{< rawhtml >}}
<div id="loading">
	Loading...
	<br><small>(If you see this for more than a few seconds, something has gone wrong...)</small>
</div>
<div id="loaded" class="hidden">
	<div class="text-center" data-algo="SHA1" data-token="SECRETCODE">
		<h3></h3>
		<div class="qr"></div>
		<br>
		<strong><span class="code"></span></strong>
		<br>
		<progress></progress> (<span class="seconds"></span>)
	</div>
	<br><br><br><br>

	<div class="text-center" data-algo="SHA256" data-token="SECRETCODE">
		<h3></h3>
		<div class="qr"></div>
		<br>
		<strong><span class="code"></span></strong>
		<br>
		<progress></progress> (<span class="seconds"></span>)
	</div>
	<br><br><br><br>

	<div class="text-center" data-algo="SHA512" data-token="SECRETCODE">
		<h3></h3>
		<div class="qr"></div>
		<br>
		<strong><span class="code"></span></strong>
		<br>
		<progress></progress> (<span class="seconds"></span>)
	</div>
</div>

<script type='text/javascript' src='./otp.js' data-noconcat='true'></script>
{{< /rawhtml >}}
