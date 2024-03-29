---
title: MD5
author: Dataforce
type: post
date: 2008-07-28T02:55:09+00:00
url: /2008/07/MD5/
category:
  - Code
  - General

---
I was recently looking at converting an old application from VB6 to Java that used MD5 in its output files as hashes for validation.

The first thing I did was to make a java class that read in the file and checked the hashes, I tried it on a few files and it worked fine, then I found a file that it failed on.

Now, this app wrote all the files using the exact same function, so it seemed odd that 1 of them wouldn't parse and the rest would.

When I looked at the file closer, I found that this one contained some symbols in the output that the others didn't - I eventually figured out that the symbol that was causing the problem was the pound sign (&pound;).

Without going into too much detail, this presented a major problem, the string in question was used as part of the password validation for the app (the output files are encrypted using the password as a key), and the java code was getting different results than the old VB6 code, and was unable to decode the file as a result.

So, this sparked my curiosity a bit, the VB6 code I was using wasn't a built in, it was code I'd gotten elsewhere and used, so I assumed it was faulty code (not that this helped me much, as I needed to get the exact same output, but ignoring that).

<!--more-->

I edited the initial form of my application to return the MD5 String for `&pound;` on its own, and got: `d527ca074d412d9d0ffc844872c4603c`

I did the same for my java code and got: `6465dad1d31752be3f3283e8f70feef7`

So now all I needed to do was to see which was right, so I made a quick PHP script, and did the same and got: `d99731d14c7750048538404febb0e357` ... Yet another different hash!?

Ok, I thought, md5sum will help me figure out which one is right. one `echo '&pound;' | md5sum -` and I had `67160ce935d7cb5339047b12ad4611cb`. Yes, that is correct, a 4th different hash.

So here I was with 4 different hashes and no idea which one was correct.

So after a bit of googling, I discovered that the MD5 RFC (1321) had the source code for a test application in it.

So I extracted the code from the Appendix of http://www.ietf.org/rfc/rfc1321.txt and tried to compile it with `gcc md5.c mddriver.c -o mddriver` only to discover that it failed to compile with lots of errors, fortunately this was an easy fix, near the top of mddriver.c, change `#define MD MD5` to `#define MD 5` and then it compiles without problem.

So, I ran `./mddriver -s&pound;` and got the output `MD5 ("&pound;") = d99731d14c7750048538404febb0e357` which agreed with what the PHP md5() function gave.

(Its worth noting that `echo '&pound;' | ./mddriver` agreed with md5sum, which made me remember that `echo` appends a `\n`, which was why I got a different output, running `echo -n '&pound;' | md5sum` gives the correct result, and would have saved me googling and finding the test suite!)

I tested a few other things and got the following results:

```
        mddriver: d99731d14c7750048538404febb0e357
             PHP: d99731d14c7750048538404febb0e357
           mySQL: d99731d14c7750048538404febb0e357
          python: d99731d14c7750048538404febb0e357
      postgreSQL: d99731d14c7750048538404febb0e357
          md5sum: d99731d14c7750048538404febb0e357

      JavaScript: d527ca074d412d9d0ffc844872c4603c
     VisualBasic: d527ca074d412d9d0ffc844872c4603c
         Eggdrop: d527ca074d412d9d0ffc844872c4603c
   Java (custom): d527ca074d412d9d0ffc844872c4603c

 Java (built in): 6465dad1d31752be3f3283e8f70feef7
```

 * JavaScript implementation from http://pajhome.org.uk/crypt/md5/
 * VisualBasic implementation from http://www.frez.co.uk/freecode.htm#md5;
 * Custom Java implementation from http://www.freevbcode.com/ShowCode.Asp?ID=741

There is also a list of MD5 implementations at <http://userpages.umbc.edu/~mabzug1/cs/md5/md5.html>

* * *

The differences are primarily due to character encoding in the different languages. (In the case of my app, there was also a flaw in the implementation for strings where (length % 64) is > than 55 as well)

Example:

```shell
[07:14:55] [shane@Xion:~]$ php -r 'echo md5(utf8_encode("£"))."\n";'
2ccf59396b3c0958eec4ba721e2d083f
[07:15:01] [shane@Xion:~]$ php -r 'echo md5("£")."\n";'
d99731d14c7750048538404febb0e357
```

```
Java: System.out.println((int)'£'); => "163"
PHP: echo ord('£'); => "194"
PHP: echo ord(utf8_encode('£')); => "195"
```
