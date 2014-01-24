#!/usr/bin/gawk -f

/^include::/ {
    file = SRC_DIR "/" substr($0, 10, length($0)-9-2);
    while (getline line<file != 0) {
        if (match(line, /^(=+ )(.*)$/, a) > 0) {
            level = a[1];
            title = a[2];
            break;
        }
    }
    close(file);
    print $0 " #!prefix=\"" level "\",id-base=\"" ID_PREFIX "\",title=\"" title "\"";
    next;
}

{
    print;
}
