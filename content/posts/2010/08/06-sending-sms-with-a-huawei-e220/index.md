---
title: Sending SMS with a Huawei E220
author: Dataforce
type: post
date: 2010-08-06T09:15:09+00:00
url: /2010/08/sending-sms-with-a-huawei-e220/
category:
  - General

---
Today I decided to play with an old Huawei E220 I have lying around.

After getting it setup and recognised in Linux by following the first 5 steps from http://ubuntuforums.org/showthread.php?p=3656717

After this, restarting udev (`restart udev`) and replugging the device makes it ready to use.

Part of the testing I was doing, was to send text-messages using the device (as a way of sending status messages out-of-band if an internet connection isn't available.) and threw together this quick script that relies on `expect` and `kermit`:

```tcl
#!/usr/bin/expect -f
####################################################
# Copyright (c) 2010 Shane Mc Cormack
####################################################
# This script is used to send text messages using
# any AT-Compatible SMS-Capable serial device.
####################################################

if {[llength $argv] &lt; 3} {
	puts "Usage: $argv0 '&lt;device>' '&lt;number>' '&lt;message>'";
	puts "&lt;number> should be in international format.";
	exit 1;
}

set device [lindex $argv 0]
set number [lindex $argv 1]
set message [lindex $argv 2]

set escape "\x1C";

set timeout 25
match_max 100000

puts "Spawning: /usr/bin/kermit -b 9600 -8 -l ${device} -C "set exit warning off,set carrier-watch off,connect,exit""
spawn /usr/bin/kermit -b 9600 -8 -l ${device} -C "set exit warning off,set carrier-watch off,connect,exit"

expect -- "----------------------------------------------------" { send "AT+CMGF=1\r\n" }
expect -- "OK" { send "AT+CMGS="${number}"\r" }
expect -- ">" { send "${message}\032" }

expect -- "OK" {
	puts "";
	send "${escape}";
	send "c"
}
```

Usage is simple:

```shell
[09:51:22] [shane@ShanePc:~/3gsms]$ ./sendSMS.sh /dev/ttyUSB0 "+447XXXXXXXXX" "Test message from CLI"
Spawning: /usr/bin/kermit -b 9600 -8 -l /dev/ttyUSB0 -C "set exit warning off,set carrier-watch off,connect,exit"
spawn /usr/bin/kermit -b 9600 -8 -l /dev/ttyUSB0 -C set exit warning off,set carrier-watch off,connect,exit
Connecting to /dev/ttyUSB0, speed 9600
 Escape character: Ctrl-\ (ASCII 28, FS): enabled
Type the escape character followed by C to get back,
or followed by ? to see other options.
----------------------------------------------------
AT+CMGF=1
OK
AT+CMGS="+447XXXXXXXXX"
> Test message from CLI

+CMGS: 11

OK

[09:51:31] [shane@ShanePc:~/3gsms]$
```

Perfect.
