#!/bin/bash
# vim: sts=4 sw=4 ts=4 et

# Generate toc
echo asciidoc --backend docbook -o index.xml main-html.asciidoc
echo "GENERATE TOC!"

# Generate each HTML files
find -type f -name '*.asciidoc' -not -name 'main*' | while read f; do
    if [ -d '${f#.asciidoc}' ]; then
        # Change file to have only intro
        echo grep -v '^include::' "$f" '|' asciidoc --backend html5 -o "${f%.asciidoc}.html" "$f"
    else
        echo asciidoc --backend html5 -o "${f%.asciidoc}.html" "$f"
    fi
done
