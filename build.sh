#!/bin/bash

set -uxeo pipefail

DIR="$(dirname "$(readlink -f "$0")")"

cd ${DIR}

PATH=${PATH} hugo
