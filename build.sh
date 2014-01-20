#!/bin/bash
# vim: sts=4 sw=4 ts=4 et

set -e

# Generate toc
echo "Generating ToC"
asciidoc --backend docbook -o index.xml main-html.asciidoc
./toc.py index.xml > toc.html

# Generate each HTML files
find -type f -name '*.asciidoc' -not -name 'main*' | while read f; do
    pathBase="$(dirname "${f#./}")"
    if [ "$pathBase" = "." ]; then
        idBase=""
    else
        idBase="${pathBase//\//-}-"
    fi
    id="${f#./}"
    id="${id%.asciidoc}"
    id="${id//\//-}"
    out="${f%.asciidoc}.html"
    if [ -d "${f%.asciidoc}" ]; then
        echo "$f [$id] intro"
        # Change file to have only intro
        # and link to the included files
        awk 'BEGIN { base="'"$pathBase"'/" } /^include::/ { file = base substr($0, 10, length($0)-9-2); while (getline line<file != 0) { if (match(line, /^(=+ )(.*)$/, a) > 0) { level=a[1]; title = a[2]; break } }; close(file); print $0 " #!prefix=\"" level "\",title=\"" title "\""; next }; {print}' "$f" \
        | sed -r -e "s/^include::(.*)\.asciidoc\[\] #!prefix=\"([^\"]*)\",title=\"(.*)\"$/\2<<$idBase\1,\3>>\n\n--\n--/; :noslash; s/^(=* *<<[^,]*)\//\1-/; t noslash; :end;" \
        | asciidoc --backend html5 -o "$out.pre" -
        ./rewrite.py index.xml "$out.pre" > "$out"
    else
        echo "$f [$id]"
        asciidoc --backend html5 --attribute toc --attribute disable-javascript -o "$out.pre" "$f"
        ./rewrite.py index.xml "$out.pre" > "$out"
    fi
    rm "$out.pre"
done
