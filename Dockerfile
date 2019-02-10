##
## Step 1 - add content and build
##

FROM debian:stretch as build
RUN apt-get -qq update \
	&& DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends python-pygments git ca-certificates asciidoc yui-compressor tidy webp \
	&& rm -rf /var/lib/apt/lists/*

ENV HUGO_VERSION 0.54.0
ENV HUGO_BINARY hugo_${HUGO_VERSION}_Linux-64bit.deb

ADD https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/${HUGO_BINARY} /tmp/hugo.deb
RUN dpkg -i /tmp/hugo.deb \
	&& rm /tmp/hugo.deb

ADD . /tmp/build

RUN /tmp/build/build.sh

##
## Step 3 - host!
##

FROM nginx:mainline-alpine AS nginx
COPY --from=build /tmp/build/public /usr/share/nginx/html
ADD nginx.conf /etc/nginx/nginx.conf
