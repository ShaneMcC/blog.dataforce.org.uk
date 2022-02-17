#!/bin/sh

# Crazy/Stupid but fun idea of optionally running the site in a ramdisk...
if [ -e /usr/share/nginx/tmp-html ]; then
	rm -Rfv /usr/share/nginx/tmp-html/*
	cp -Rfv /usr/share/nginx/html/. /usr/share/nginx/tmp-html
	sed -i 's#/usr/share/nginx/html#/usr/share/nginx/tmp-html#g' /etc/nginx/nginx.conf
fi;
