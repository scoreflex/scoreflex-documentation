#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4 sts=4 sw=4 et

import os
import sys
import cStringIO
import BeautifulSoup

import toc
tocModule = toc



def clean(soup, toc, ref):
    # Rewrite links
    for link in soup.findAll('a'):
        href = link.get('href')
        if href is None:
            print "WARNING: Link with no href:", link
            continue
        if href.startswith('#') and href != '#':
            href = href[1:]
            if soup.find(attrs={'id': href}) is not None or soup.find("a", attrs={'name': href}) is not None:
                # Link to an element in the page
                continue
            target = toc.walk_id(href)
            if target is None:
                print "WARNING: Link to an unknown ToC entry \"%s\"" % href
                continue
            link['href'] = target.link(ref)
    # Add ToC in header
    tocElmt = soup.find("div", attrs={'id': 'toc'})
    if tocElmt is not None:
        # Remove toc's noscript
        noscript = tocElmt.find("noscript")
        if noscript is not None:
            noscript.extract()
        # Inject ToC
        tocHTMLBuffer = cStringIO.StringIO()
        ref.write_html(tocHTMLBuffer)
        tocTags = BeautifulSoup.BeautifulSoup(tocHTMLBuffer.getvalue())
        tocHTMLBuffer.close()
        tocElmt.append(tocTags)
    # Return just the interesting html, not the boilerplate
    rtn = soup.body
    rtn.name = 'div'
    return rtn



def usage(args):
    print "Usage:", args[0], "-h|--help"
    print "      ", args[0], "TOC FILE"
    print "Rewrites the generated page so that it fits well in the whole website."
    print "    TOC     DocBook XML file to extract the ToC from."
    print "    FILE    The relative path to the file to rewrite."

def main(args):
    if len(args) != 3:
        usage(args)
        return 1
    if args[1] == '-h' or args[1] == '--help':
        usage(args)
        return 0
    tocFile = sys.argv[1]
    htmlFile = sys.argv[2]

    id = os.path.relpath(htmlFile)
    while True:
        id, ext = os.path.splitext(id)
        if len(ext) == 0: break
    id = id.replace(os.path.sep, '-')

    toc = tocModule.tocFromFile(tocFile, False)
    ref = toc.walk_id(id)
    if ref is None:
        print "ERROR: The file id \"%s\" was not found in the ToC!" % id
        return 1

    htmlFp = open(htmlFile, "rw")
    soup = BeautifulSoup.BeautifulSoup(htmlFp)
    out = clean(soup, toc, ref)
    print out
    htmlFp.close()

    return 0

if __name__ == '__main__':
    rtn = main(sys.argv)
    sys.exit(rtn)
