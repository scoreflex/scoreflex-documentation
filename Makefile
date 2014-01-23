#!/usr/bin/make -f

all:

#
# System commands
#

ASCIIDOC ?= asciidoc
CP ?= cp
DIRNAME ?= dirname
FIND ?= find
RM ?= rm

#
# Local scripts
#

TREE_TO_MAKEFILE := ./tree-to-makefile.sh
TOC := ./toc.py
REWRITE := ./rewrite.py
ID_FROM_RELPATH := ./id-from-relpath.sh
SHIFT_TITLE_LEVELS := ./shift-title-levels.awk
GET_INCLUDE_INFOS := ./get-include-infos.awk
INCLUDE_WITH_INFO_TO_TITLE := ./include-with-info-to-title.sed

#
# Auto-generated part
#

ASCIIDOC_REGULAR_FILES :=
ASCIIDOC_FOLDER_FILES :=
define newline


endef
$(eval $(subst #,$(newline),$(shell $(TREE_TO_MAKEFILE) | tr '\n' '#')))
HTML_REGULAR_FILES := $(patsubst %.asciidoc, %.html, $(ASCIIDOC_REGULAR_FILES))
HTML_FOLDER_FILES  := $(patsubst %.asciidoc, %.html, $(ASCIIDOC_FOLDER_FILES))

#
# Manipulated files
#

HTML_FILES := $(HTML_REGULAR_FILES) $(HTML_FOLDER_FILES)
FULLTOC := fulltoc.html
DOCBOOK_FILE := index.xml
DOCBOOK_STAMP := $(DOCBOOK_FILE).stamp

#
# Phony targets
#

.PHONY: all clean distclean FORCE

all: toc.html $(HTML_FILES)

clean:
	$(RM) -Rf $(DOCBOOK_FILE) $(FULLTOC) $(HTML_FILES)

distclean: clean
	$(FIND) . -type f '(' -name '*.xml' -or -name '*.html' -or -name '*.html.pre' -or -name '*.asciidoc.pre' ')' -delete

FORCE:

#
# File targets
#

$(FULLTOC): $(DOCBOOK_FILE)
	@echo "Checking if ToC changed"
	$(TOC) "$(DOCBOOK_FILE)" '' > "$@.new"
	cmp -s "$@" "$@.new" || touch $(DOCBOOK_STAMP)
	mv "$@.new" "$@"

$(DOCBOOK_STAMP): FORCE
	$(MAKE) "$(FULLTOC)"
	[ -f "$@" ] || touch "$@"

$(DOCBOOK_FILE): main-html.asciidoc $(ASCIIDOC_REGULAR_FILES) $(ASCIIDOC_FOLDER_FILES)
	@echo "Building docbook"
	@$(ASCIIDOC) --backend docbook -o "$@" "$<"

toc.html: $(DOCBOOK_STAMP)
	@echo "Building ToC"
	@$(TOC) "$(DOCBOOK_FILE)" > "$@"

%.html: %.html.pre
	@$(REWRITE) $(DOCBOOK_FILE) "$<" > "$@"

$(HTML_REGULAR_FILES): $(DOCBOOK_STAMP)

$(HTML_REGULAR_FILES):
	@echo "Building $<"
	@$(SHIFT_TITLE_LEVELS) "$<" \
	| $(ASCIIDOC) --backend html5 --attribute toc --attribute disable-javascript -o - - \
	| $(REWRITE) $(DOCBOOK_FILE) "$<" > "$@" || ( rm "$@" && false )

$(HTML_FOLDER_FILES): $(DOCBOOK_STAMP)

$(HTML_FOLDER_FILES):
	@echo "Building $<"
	@$(GET_INCLUDE_INFOS) -v SRC_DIR="$$($(DIRNAME) "$<")" -v ID_PREFIX="$$($(ID_FROM_RELPATH) --base "$<")" "$<" \
	| $(INCLUDE_WITH_INFO_TO_TITLE) \
	| $(SHIFT_TITLE_LEVELS) \
	| $(ASCIIDOC) --backend html5 --attribute toc --attribute disable-javascript -o - - \
	| $(REWRITE) $(DOCBOOK_FILE) "$<" > "$@" || ( rm "$@" && false )
