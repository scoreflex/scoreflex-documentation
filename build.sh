#!/bin/bash
# vim: sts=4 sw=4 ts=4 et

set -e

# Generate toc
echo "Generating ToC"
asciidoc --backend docbook -o index.xml main-html.asciidoc
./toc.py index.xml > toc.html

# Generate each HTML files
find -type f -name '*.asciidoc' -not -name 'main*' | while read f; do
    if [ -d "${f%.asciidoc}" ]; then
        echo "$f intro"
        # Change file to have only intro
        # and link to the included files
        pathBase="$(dirname "${f#./}")"
        if [ "$pathBase" = "." ]; then
            idBase=""
        else
            idBase="${pathBase//\//-}-"
        fi
        awk 'BEGIN { base="'"$pathBase"'/" } /^include::/ { file = base substr($0, 10, length($0)-9-2); while (getline line<file != 0) { if (match(line, /^(=+ )(.*)$/, a) > 0) { level=a[1]; title = a[2]; break } }; close(file); print $0 " #!prefix=\"" level "\",title=\"" title "\""; next }; {print}' "$f" \
        | sed -r -e "s/^include::(.*)\.asciidoc\[\] #!prefix=\"([^\"]*)\",title=\"(.*)\"$/\2<<$idBase\1,\3>>\n\n--\n--/; :noslash; s/^(=* *<<[^,]*)\//\1-/; t noslash; :end;" \
        | asciidoc --backend html5 -o "${f%.asciidoc}.html" -
    else
        echo "$f"
        asciidoc --backend html5 -o "${f%.asciidoc}.html" "$f"
    fi
done
