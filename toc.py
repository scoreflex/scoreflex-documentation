#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: ts=4 sts=4 sw=4 et

import sys
import xml.dom.minidom
minidom = xml.dom.minidom
import re

auto_generated_id = re.compile(r'^_.*$')
auto_generated_id_conflict = re.compile(r'^_.*_\d+$')


class TocEntry():

    def __init__(self, id=None, title=None):
        self.parent = None
        self.id = id
        self.title = title
        self.chunkPage = False
        self.chunkToc = False
        self.children = []

    def append(self, child):
        self.children.append(child)
        child.parent = self

    def is_root(self):
        return self.parent is None # or self.id is None

    def depth(self):
        if self.is_root():
            return 0
        return 1 + self.parent.depth()

    def link(self):
        if self.is_root():
            return ''
        # Get where the page starts
        chunkPageParent = self
        while not chunkPageParent.is_root():
            if chunkPageParent.chunkPage:
                break
            chunkPageParent = chunkPageParent.parent
        if chunkPageParent.is_root():
            # No page parent found
            chunkPageParent = self
        parentParts = []
        curr = chunkPageParent
        while not curr.is_root():
            parentParts.append(curr.id)
            curr = curr.parent
        parentParts.reverse()
        parentParts = '/'.join(parentParts)
        # Add the id of self directly, no hierarchy
        # unless self is a page itself
        glue = '#'
        selfPart = self.id
        if chunkPageParent is self:
            glue = ''
            selfPart = ''
        return parentParts + glue + selfPart

    def __str__(self):
        parts = []
        curr = self
        while curr.id is not None:
            parts.append(curr.title.encode('utf-8'))
            curr = curr.parent
        parts.reverse()
        return ' / '.join(parts) + (' […]' if self.chunkToc else '') + (' [PAGE]' if self.chunkPage else '') + (' [LEAF]' if len(self.children) == 0 else '') + ' #' + unicode(self.id).encode('utf-8') + ' href:' + self.link().encode('utf-8')

    def walk(self, callback):
        if self.id is not None:
            callback(self)
        for child in self.children:
            child.walk(callback)

    def rec_print(self):
        def print_me(item):
            print str(item)
        self.walk(print_me)



def isNodeTag(node, tag):
    return node.nodeType == minidom.Node.ELEMENT_NODE and node.nodeName == tag

def getText(node):
    rc = []
    for child in node.childNodes:
        if child.nodeType == node.TEXT_NODE:
            rc.append(child.data)
        else:
            rc.append(getText(child))
    return ''.join(rc)

def getTitle(node):
    for title in node.childNodes:
        if not isNodeTag(title, 'title'): continue
        return getText(title)
    return None

def shouldChunkToc(node):
    return 'chunk-toc' in node.getAttribute('role')

def shouldChunkPage(node):
    return 'chunk-page' in node.getAttribute('role')

def parseLevels(node, levels, currToc):
    sublevels = levels[1:]
    if len(sublevels) == 0: sublevels = levels
    for part in node.childNodes:
        if not isNodeTag(part, levels[0]): continue
        partId = part.getAttribute('id')
        partTitle = getTitle(part)
        childToc = TocEntry(partId, partTitle)
        childToc.chunkPage = shouldChunkPage(part)
        childToc.chunkToc = shouldChunkToc(part)
        currToc.append(childToc)
        if auto_generated_id.match(partId):
            print 'NOTE:', str(childToc), 'has an auto-generated id!'
            if auto_generated_id_conflict.match(partId):
                print 'WARNING:', str(childToc), 'conflicts with an earlier auto-generated id, such link will be broken!'
        if childToc.chunkToc: continue
        parseLevels(part, sublevels, childToc)
    
def extractToc(dom):
    toc = TocEntry()
    for book in dom.childNodes:
        if not isNodeTag(book, 'book'): continue
        parseLevels(book, ['part', 'chapter', 'section'], toc)
        break
    return toc



def usage(args):
    print "Usage:", args[0], "-h|--help"
    print "      ", args[0], "FILE"
    print "Extracts a Table of Contents from a DocBook."
    print "    FILE    DocBook XML file to extract the ToC from."

def main(args):
    if len(args) != 2:
        usage(args)
        return 1
    if args[1] == '-h' or args[1] == '--help':
        usage(args)
        return 0

    dom = minidom.parse(sys.argv[1])
    toc = extractToc(dom)
    toc.rec_print()

    return 0

if __name__ == '__main__':
    rtn = main(sys.argv)
    sys.exit(rtn)
