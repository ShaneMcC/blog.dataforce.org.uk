#!/bin/bash

set -uxeo pipefail

DIR="$(dirname "$(readlink -f "$0")")"

cd ${DIR}

YUI=`which yui-compressor`
CWEBP=`which cwebp`
TIDY=`which tidy`

hugo

cd public

# Compress all the CSS files together
rm css/allStyles*.css || true
cat $(grep "rel=['\"]stylesheet['\"]" $(find . -name '*.html') | awk -F: '{print $2}' | awk '!x[$0]++' | sed -r "s#.*href=['\"]/([^'\"]+)['\"].*#\1#g") > "css/allStyles-concat.css"
STYLE="/css/allStyles-concat.css"

if [ -e "${YUI}" ]; then
	${YUI} "css/allStyles-concat.css" > "css/allStyles-compressed.css"
	if [ $? -eq 0 ]; then
		rm "css/allStyles-concat.css"
		STYLE="/css/allStyles-compressed.css"
	fi;
fi;

CSSHASH=`md5sum ".${STYLE}" | awk '{print $1}'`

mv ".${STYLE}" "css/allStyles-${CSSHASH}.css"


# Compress all the JS files together
rm js/allScripts*.js || true
cat $(grep "script.*type=['\"]text/javascript['\"]" $(find . -name '*.html') | grep -v "data-noconcat=['\"]true['\"]" | awk -F: '{print $2}' | awk '!x[$0]++' | sed -r "s#.*src=['\"]/([^'\"]+)['\"].*#\1#g") > "js/allScripts-concat.js"
SCRIPT="/js/allScripts-concat.js"

if [ -e "${YUI}" ]; then
	${YUI} "js/allScripts-concat.js" > "js/allScripts-compressed.js"
	if [ $? -eq 0 ]; then
		rm "js/allScripts-concat.js"
		SCRIPT="/js/allScripts-compressed.js"
	fi;
fi;

JSHASH=`md5sum ".${SCRIPT}" | awk '{print $1}'`

mv ".${SCRIPT}" "js/allScripts-${JSHASH}.js"



# Tidy up each generated file.
for FILE in $(find . -name '*.html'); do
	# Remove styles from HTML.
	sed -i "\#rel=['\"]stylesheet['\"]#d" "${FILE}"
	# Add new style.
	sed -i 's#</head>#<link rel="stylesheet" href="/css/allStyles-'${CSSHASH}'.css" type="text/css" media="all" /></head>#g' "${FILE}"

	# Remove JS from HTML.
	sed -i "\#type=['\"]text/javascript['\"]#d" "${FILE}"
	# Add new script.
	sed -i 's#</body>#<script type="text/javascript" src="/js/allScripts-'${JSHASH}'.js"></script></body>#g' "${FILE}"

	if [ -e "${TIDY}" ]; then
		${TIDY} --tidy-mark no -q -i -w 120 -m --vertical-space yes --drop-empty-elements no "${FILE}" || true
	fi;
done

# Convert all images to WebP
if [ -e "${CWEBP}" ]; then
	for FILE in $(find . -name '*.jpg' -o -name '*.png' -o -name '*.jpeg'); do
		${CWEBP} -m 6 -mt -o "${FILE}.webp" -- "${FILE}"
	done
fi;

