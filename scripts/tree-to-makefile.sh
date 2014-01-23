#!/bin/bash

SCRIPTS_DIR="$(dirname "$0")"
SRCDIR="$SCRIPTS_DIR/.."

find "$SRCDIR" -type f -name '*.asciidoc' -not -name 'main*.asciidoc' | while read f; do
    f="${f#$SRCDIR/}"
    if [ -d "${f%.asciidoc}" ]; then
        echo "ASCIIDOC_FOLDER_FILES += \$(SRCDIR)/$f"
        echo "HTML_FOLDER_FILES += \$(HTML_BUILDDIR)/${f%.asciidoc}.html"
    else
        echo "ASCIIDOC_REGULAR_FILES += \$(SRCDIR)/$f"
        echo "HTML_REGULAR_FILES += \$(HTML_BUILDDIR)/${f%.asciidoc}.html"
    fi
    echo "\$(HTML_BUILDDIR)/${f%.asciidoc}.html: \$(SRCDIR)/$f"
    # Add include dependencies
    dirname="$(dirname "$f")/"
    if [ "$dirname" = "./" ]; then
        dirname=""
    fi
    sed -n -r -e 's|^include::([^\[]*)\[.*$|$(HTML_BUILDDIR)/'"${f%.asciidoc}"'.html: $(SRCDIR)/'"$dirname"'\1|p' "$SRCDIR/$f"
done
