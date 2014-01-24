#!/usr/bin/gawk -f
BEGIN {
    remove = -1;
}

remove == -1 && /^=+ / {
    remove = index($0, " ") - 1;
}

remove > 0 && /^=+ / {
    print substr($0, remove);
    next;
}

{
    print;
}
