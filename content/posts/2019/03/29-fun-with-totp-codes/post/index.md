---
title: "Fun with TOTP Codes"
author: Dataforce
url:  /2019/03/fun-with-totp-codes/
image: qr.png
description: Fun with TOTP Codes.
type: post
date: 2019-03-29T04:20:00Z
category:
  - Code
---

This all started with a comment I overheard at work from a colleague talking about a 2FA implementation on a service they were using.

> "It works fine on everything except Google Authenticator on iPhone."

... What? This comment alone immediately piqued my interest, I stopped what I was doing, turned round, and asked him to explain.

He explained that a service he was using provided 2FA support using TOTP codes. As is normal, they provided a QR Code, you scanned it with your TOTP application (Google Authenticator or Authy or so), then you typed in the verification code - and it worked for both Google Authenticator and Authy on his Android phone, but only with Authy and not Google Authenticator on another colleagues iPhone.

This totally [nerd sniped](https://xkcd.com/356/) me, and I just had to take a look.

The first thing I tried was to look at some "known-good" codes. I support RFC 6238 TOTP for [MyDNSHost](https://mydnshost.co.uk) so I started there, and looked to generate a new code on a test account. Alas, in the dev install I was using, I had broken TOTP 2FA Codes so couldn't use it test, so Googled for a site to generate the images for me, and came across: https://stefansundin.github.io/2fa-qr/

I generated a Test QR Code, scanned it into Authy on my Android phone, and Google Authenticator on my colleagues iPhone - and they both agreed on the code, and the next one, and so on.

We then copied the code from service we were using and pasted that to the generator and scanned the new QR code in... and it also worked fine. Interesting.

So, the next thing to do was to to compare the difference between the URLs. QR Codes for TOTP are actually just text that looks somewhat like: `otpauth://totp/TestService?secret=TESTTEST` ([Key URI Format](https://github.com/google/google-authenticator/wiki/Key-Uri-Format))

So looking at the 2 QR Codes:

 - Generated QR Code: `otpauth://totp/TestService?secret=LJZC6S3XHFHHMMDXNBJC4LDBJYZCMU35`[^1]
 - Service QR Code: `otpauth://totp/TestService?secret=LJZC6S3XHFHHMMDXNBJC4LDBJYZCMU35&algorithm=SHA512`[^1]

Interesting! The service was doing something different, it seemed to be suggesting that a different algorithm should be used, this was not something I was aware of so I then looked at [RFC 6238](https://tools.ietf.org/html/rfc6238) to see what it had to say about the algorithms, it states:

> TOTP implementations MAY use HMAC-SHA-256 or HMAC-SHA-512 functions,
>
> based on SHA-256 or SHA-512 [SHA2] hash functions, instead of the
>
> HMAC-SHA-1 function that has been specified for the HOTP computation
>
> in [RFC4226].

So this was valid after all... Was the iPhone doing something wrong? I couldn't find any bug reports suggesting as much from some cursory googling.

Looking back at the web-based generator website, it has an "advanced options" field which lets us change the algorithm in the generated code, so I made some test QR Codes, all with the same secret, but 1 of each algorithm (`SHA1`, `SHA256`, `SHA512`).

I then imported all 3 into Google Authenticator on both Android and a spare iPhone and took a look at the output:

{{< postimage src="phones.png" large="phones.png" side="middle" alt="Phones showing TOTP Codes" >}}

Ah... no, it does not look like it's the iPhone at fault here. Infact it very much appears like the opposite[^2], it appears that the Google Authenticator app on iPhone is the only one that correctly cares about the algorithm provided. Google Authenticator on Android and Authy on either Android or iPhone all appear to just ignore the Algorithm param and default to SHA1.

It also even looks like the service that was providing these codes was not validating it correctly, and also was expecting the SHA1 code despite asking for SHA512.

This looked like the end of it, but I wanted to be sure. I decided to throw together a quick php script to test the theory. I normally use [PHPGangsta/GoogleAuthenticator](https://github.com/PHPGangsta/GoogleAuthenticator) for my GoogleAuthenticator validation, so I set about modifying that to support the different algorithms (Modified code is available [here](https://github.com/shanemcc/PHPGangsta-GoogleAuthenticator)), and then produced this test script[^3]:

```php
<?php
	require_once(__DIR__ . '/PHPGangsta-GoogleAuthenticator/PHPGangsta/GoogleAuthenticator.php');

	$ga = new PHPGangsta_GoogleAuthenticator();
	$ga->setCodeLength(6);

	$secret = 'LJZC6S3XHFHHMMDXNBJC4LDBJYZCMU35';
	$time = floor(time() / 30);
	$time = '51793295'; // Comment this out for real-time codes.

	echo 'Time: ', $time, "\n\n";
	echo 'Code SHA1: ', $ga->getCode($secret, $time, 'SHA1'), "\n";
	echo 'Code SHA256: ', $ga->getCode($secret, $time, 'SHA256'), "\n";
	echo 'Code SHA512: ', $ga->getCode($secret, $time, 'SHA512'), "\n";
	echo "\n";
```

I ran the script, and compared it's output to the phones - The script agreed with the iPhone:

```bash
$ php test.php
Time: 51793295

Code SHA1: 583328
Code SHA256: 972899
Code SHA512: 911582

$
```

I've also created a demo page [here]({{< ref "demo/index.md" >}}) that displays 3 qr codes (1 for each algorithm, all with the same secret) and their expected output to allow people to reproduce this on their own devices.

So that's that[^4]. Looks like the reason it works on everything except Google Authenticator on iPhone... is because everything else is wrong.

**Update 1**: Looks like there is a bug report for Google Authenticator on Android for this [here](https://github.com/google/google-authenticator-android/issues/29)

[^1]: This TOTP code is not actually used live anywhere, and is for demonstration purposes only.
[^2]: This was painful for me to admit out loud to my colleague...
[^3]: For demonstration purposes this script uses a fixed timeslice to match up with the earlier picture.
[^4]: Yes, I have been in contact with the service in question to point out the problem to them.
