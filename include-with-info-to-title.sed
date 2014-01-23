#!/bin/sed -f

s/^include::\(.*\)\.asciidoc\[\] #!prefix="\([^"]*\)",id-base="\([^"]*\)",title="\(.*\)"$/\2<<\3\1,\4>>\n\n--\n--/

:noslash
s/^\(=* *<<[^,]*\)\//\1-/
t noslash

:end
