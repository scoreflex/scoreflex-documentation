#!/bin/bash

base=
if [ "$1" = "--base" ]; then
    base=1
    shift
fi
file="$1"

pathBase="$(dirname "${file#./}")"

if [ "$pathBase" = "." ]; then
    idBase=""
else
    idBase="${pathBase//\//-}-"
fi

id="${1#./}"
id="${id%.asciidoc}"
id="${id//\//-}"

if [ -n "$base" ]; then
    echo "$idBase"
else
    echo "$id"
fi
