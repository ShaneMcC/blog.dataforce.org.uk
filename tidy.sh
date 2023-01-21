#!/bin/bash

set -uxeo pipefail

DIR="$(dirname "$(readlink -f "$0")")"

cd ${DIR}/public

CWEBP=`which cwebp || true`
TIDY=`which tidy || true`
GZIP=`which gzip || true`
BROTLI=`which brotli || true`
PURGECSS=`which purgecss || true`
JAMPACK=`which jampack || true`

# Tidy up each generated file.
if [ -e "${TIDY}" ]; then
	for FILE in $(find . -name '*.html'); do
		${TIDY} --tidy-mark no -q -i -w 120 -m --vertical-space yes --drop-empty-elements no "${FILE}" || true
	done
fi;

# Convert all images to WebP
# if [ -e "${CWEBP}" ]; then
# 	for FILE in $(find . -name '*.jpg' -o -name '*.png' -o -name '*.jpeg'); do
# 		if [ ! -e "${FILE}.webp" ]; then
# 			${CWEBP} -m 6 -mt -o "${FILE}.webp" -- "${FILE}" || true
# 		fi;
# 	done
# fi;

# Remove unused CSS
if [ -e "${PURGECSS}" ]; then
	${PURGECSS} --variables --font-face --keyframes --output css/ --css css/style.min.*.css --content '**.html' '**/*.html'
fi;

# Run Jampack to compress images/files etc
# https://jampack.divriots.com/
if [ -e "${JAMPACK}" ]; then
	${JAMPACK} --nocache .
fi;

rm __postcss-dummy*.html

# Generate static .gz and .br files
for FILE in $(find . -type f -a \( -name '*.html' -o -name '*.css' -o -name '*.js' -o -name '*.json' -o -name '*.xml' -o -name '*.svg' -o -name '*.txt' -o -name '*.ico' -o -name '*.ttf' -o -name '*.woff' -o -name '*.woff2' \)); do
	if [ -e "${BROTLI}" ]; then
		${BROTLI} --best "${FILE}" || true
	fi;

	if [ -e "${GZIP}" ]; then
		${GZIP} --best -k "${FILE}" || true
	fi;
done;
