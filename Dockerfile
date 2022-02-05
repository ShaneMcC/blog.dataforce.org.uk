##
## Step 1 - add content and build
##

FROM debian:stretch as build
RUN apt-get -qq update \
	&& DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends python-pygments git ca-certificates asciidoc yui-compressor tidy webp \
	&& rm -rf /var/lib/apt/lists/*

ENV HUGO_VERSION 0.92.1
ENV HUGO_BINARY hugo_extended_${HUGO_VERSION}_Linux-64bit.deb

ADD https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/${HUGO_BINARY} /tmp/hugo.deb
RUN dpkg -i /tmp/hugo.deb \
	&& rm /tmp/hugo.deb

ADD . /tmp/build

RUN /tmp/build/build.sh

##
## Step 2 - screenshot!
##

FROM alekzonder/puppeteer:latest AS screenshot

COPY --from=build /tmp/build/public /app
COPY screenshot.js /tools/screenshot.js

RUN /tools/screenshot 'file:///app/index.html'

##
## Step 3 - Tidy
##

FROM build as tidy

COPY --from=screenshot /screenshots/screenshot_1280_1024.png /tmp/build/public/screenshot.png

RUN /tmp/build/tidy.sh

##
## Step 4 - host!
##

FROM nginx:mainline-alpine AS nginx
COPY --from=tidy /tmp/build/public /usr/share/nginx/html
ADD nginx.conf /etc/nginx/nginx.conf
