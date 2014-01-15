#!/bin/bash
# vim: sts=4 sw=4 ts=4 et

set -e
set -v

# Generate toc
echo "Generating ToC"
asciidoc --backend docbook -o index.xml main-html.asciidoc
./toc.py index.xml > toc.html

# Generate each HTML files
find -type f -name '*.asciidoc' -not -name 'main*' | while read f; do
    if [ -d "${f%.asciidoc}" ]; then
        echo "$f intro"
        # Change file to have only intro
        grep -v '^include::' "$f" | asciidoc --backend html5 -o "${f%.asciidoc}.html" -
    else
        echo "$f"
        asciidoc --backend html5 -o "${f%.asciidoc}.html" "$f"
    fi
done
