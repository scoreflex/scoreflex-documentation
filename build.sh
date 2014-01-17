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
        echo "$f intro"
        # Change file to have only intro
        # and link to the included files
        awk 'BEGIN { base="'"$pathBase"'/" } /^include::/ { file = base substr($0, 10, length($0)-9-2); while (getline line<file != 0) { if (match(line, /^(=+ )(.*)$/, a) > 0) { level=a[1]; title = a[2]; break } }; close(file); print $0 " #!prefix=\"" level "\",title=\"" title "\""; next }; {print}' "$f" \
        | sed -r -e "s/^include::(.*)\.asciidoc\[\] #!prefix=\"([^\"]*)\",title=\"(.*)\"$/\2<<$idBase\1,\3>>\n\n--\n--/; :noslash; s/^(=* *<<[^,]*)\//\1-/; t noslash; :end;" \
        | asciidoc --backend html5 -o "$out" -
    else
        echo "$f $id"
        asciidoc --backend html5 --attribute toc --attribute disable-javascript -o "$out.notoc" "$f"
        ./toc.py index.xml "$id" | awk 'BEGIN { done = 0; is_in = 0 }; done == 0 && /<[^>]* id="toc"[^>]*>/ { is_in = 1 }; done == 0 && is_in == 1 && /<noscript>/ { while ((getline line<"-") > 0) print line; next; done = 1; }; { print }' "$out.notoc" > "$out"
        rm "$out.notoc"
    fi
done
