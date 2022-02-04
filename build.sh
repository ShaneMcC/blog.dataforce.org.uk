#!/bin/bash

set -uxeo pipefail

DIR="$(dirname "$(readlink -f "$0")")"

cd ${DIR}

CWEBP=`which cwebp`
TIDY=`which tidy`

PATH=${PATH} hugo

cd public

# Tidy up each generated file.
if [ -e "${TIDY}" ]; then
	for FILE in $(find . -name '*.html'); do
		${TIDY} --tidy-mark no -q -i -w 120 -m --vertical-space yes --drop-empty-elements no "${FILE}" || true
	done
fi;

# Convert all images to WebP
if [ -e "${CWEBP}" ]; then
	for FILE in $(find . -name '*.jpg' -o -name '*.png' -o -name '*.jpeg'); do
		${CWEBP} -m 6 -mt -o "${FILE}.webp" -- "${FILE}"
	done
fi;

