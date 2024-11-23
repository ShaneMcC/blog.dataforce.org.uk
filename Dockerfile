##
## Step 1 - add content and build
##

FROM node:lts as build
RUN apt-get -qq update \
	&& DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends tidy webp gzip brotli \
	&& rm -rf /var/lib/apt/lists/*

ENV HUGO_VERSION 0.139.0
ENV HUGO_BINARY hugo_extended_${HUGO_VERSION}_linux-amd64.deb


RUN wget https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/${HUGO_BINARY} -O /tmp/hugo.deb \
    && dpkg -i /tmp/hugo.deb \
	&& rm /tmp/hugo.deb

WORKDIR /tmp/build

RUN npm install -g postcss-cli autoprefixer purgecss @divriots/jampack

ADD config.toml /tmp/build/
ADD assets /tmp/build/assets
ADD layouts /tmp/build/layouts
ADD static /tmp/build/static
ADD themes /tmp/build/themes
ADD content /tmp/build/content
ADD build.sh /tmp/build/

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

ADD tidy.sh /tmp/build/

RUN /tmp/build/tidy.sh

##
## Step 4 - host!
##

FROM georgjung/nginx-brotli:mainline-alpine AS nginx

COPY --from=tidy /tmp/build/public /usr/share/nginx/html
ADD docker/nginx.conf /etc/nginx/nginx.conf
ADD docker/ramdisk.sh /docker-entrypoint.d/99-ramdisk.sh
