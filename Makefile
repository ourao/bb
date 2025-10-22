VERSION = 0.0.5
RCLONE_REMOTE=g1-bigb
REPO=aorao/bigbook

RELEASE = Document Release v$(VERSION)
TARBALL_DIR = .release
TARBALL = $(TARBALL_DIR)/compiled_v$(VERSION).tar.gz

BUILD_DIR=.build
LOG=/tmp/bbx-make.log
OUTDIR=.compiled

TARGETS_DIRS := $(BUILD_DIR) $(OUTDIR) $(OUTDIR)/src-bb
JOBNAME=acorpus
TARGETS_PDF=$(OUTDIR)/$(JOBNAME).pdf

TEX = latexmk -auxdir=$(BUILD_DIR) -xelatex -outdir=$(OUTDIR) -jobname=$(JOBNAME) -quiet 
export TEXMFHOME := /nonexistent
export TEXINPUTS := src:src//:.cmp:.cmp//:pre:pre//:

SRC_DIRS := src
SRC_DIR_CMP := .cmp

SRC_TEX_X := $(shell find $(SRC_DIRS) -name '*.tex')
SRC_TEX_Y := index.tex
SRC_TEX_Z := $(shell find $(SRC_DIR_CMP) -name '*.sty')

#TARGETS_TEX_Y := $(SRC_TEX_X:.tex=.pdf)
#TARGETS_TEX_A := $(TARGETS_TEX_Y:%=$(OUTDIR)/%)

SRC_TEX_A := $(SRC_TEX_X) $(SRC_TEX_Y) $(SRC_TEX_Z)

TARGETS = $(TARGETS_DIRS) $(TARGETS_A) $(TARGETS_B) $(TARGETS_TEX_A) $(TARGETS_PDF) $(OUTDIR)/README

all: $(TARGETS)

$(TARGETS_PDF): $(SRC_TEX_A) | $(TARGET_DIRS)
	$(TEX) -f $(SRC_TEX_Y)
	#$(TEX) -f $(SRC_TEX_Y)
	cp src/bb-a-history/* src/bb-b-bill/* src/bb-c-stories/* $(OUTDIR)/src-bb

#$(TARGETS_PDF): $(BUILD_DIR)/index.pdf | $(TARGET_DIRS)
#	cp $(BUILD_DIR)/index.pdf $@

$(OUTDIR)/README: README.md | $(TARGET_DIRS)
	cp "README.md" "$(OUTDIR)/README"

$(TARGETS_DIRS):
	mkdir -p $@

.PHONY: clean
clean:
	trash-put ".build/"

clean-pdf:
	trash-put $(TARGETS_PDF)

rebuild:
	@$(MAKE) clean
	@$(MAKE)

open:
	zathura $(TARGETS_PDF) &

log:
	nvim $(LOG)

$(TARBALL): $(TARGETS)
	mkdir -p $(TARBALL_DIR)
	tar -czvf $(TARBALL) --transform 's,^\.compile,doc,' -C . $(OUTDIR)

mirror: all
	# release compiled and src into separate hierarchies on the remote
	rclone sync \
		-P --track-renames \
		$(CURDIR)/$(OUTDIR) \
		$(RCLONE_REMOTE):doc
	
	rclone sync \
		-P --track-renames \
		--exclude ".compiled/**" \
		--exclude ".build/**" \
		--exclude ".git/**" \
		--exclude ".release/**" \
		#--exclude ".cmp/**" \
		$(CURDIR)/ \
		$(RCLONE_REMOTE):src

release-gh: $(TARBALL)
	gh release create "v$(VERSION)" $(TARBALL) \
        -R $(REPO) \
        --title "$(RELEASE)" \
        --notes "Release notes for $(RELEASE)"

release-archive: $(TARBALL)
	cp $(TARBALL) $(ARCHIVE_DIR)/

