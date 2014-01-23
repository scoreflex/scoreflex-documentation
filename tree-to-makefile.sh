#!/bin/bash
find . -type f -name '*.asciidoc' -not -name 'main*.asciidoc' | while read f; do
    if [ -d "${f%.asciidoc}" ]; then
        echo "ASCIIDOC_FOLDER_FILES += $f"
    else
        echo "ASCIIDOC_REGULAR_FILES += $f"
    fi
    echo "${f%.asciidoc}.html: $f"
    # Add include dependencies
    sed -n -r -e 's|^include::([^\[]*)\[.*$|'"${f%.asciidoc}.html: $(dirname "$f")/"'\1|p' "$f"
done
