VERSION 			:= 0.1.3
RCLONE_REMOTE		:= g1-bigb
REPO				:= aorao/bigbook

RELEASE 			:= Document Release v$(VERSION)
TARBALL_DIR 		:= .release
TARBALL 			:= $(TARBALL_DIR)/compiled_v$(VERSION).tar.gz

BUILD_DIR			:= .build
OUTDIR				:= .compiled
LOG					:= /tmp/bbx-make.log

#QUIET				:= -quiet
JOBNAME				:= acorpus

export TEXMFHOME 	:= /nonexistent
export TEXINPUTS 	:= src:src//:.cmp:.cmp//:pre:pre//:

SRC_DIR 			:= src
SRC_CMP 			:= .cmp
SRC_TEX_X 			:= index.tex

SRC_TEX_Y := $(shell find $(SRC_DIR) -name '*.tex')
SRC_TEX_Z := $(shell find $(SRC_CMP) -name '*.sty')

SRC_TEX_A := $(SRC_TEX_X) $(SRC_TEX_Y) $(SRC_TEX_Z)

SRC_TEX_BB := $(shell find src/bb -name '*.tex')
TAR_TEX_BB := \
	$(foreach src,\
	$(SRC_TEX_BB),\
	$(OUTDIR)/src-bb/$(shell basename $(shell dirname $(src)))/$(shell basename $(src)))

TAR_DIR 	:= $(BUILD_DIR) $(OUTDIR) $(OUTDIR)/src-bb

TAR_PDF		:= $(OUTDIR)/$(JOBNAME).pdf

TAR_READ    := $(OUTDIR)/README

TAR 		:= $(TAR_DIR) $(TAR_PDF) $(TAR_TEX_BB)

TEX = latexmk \
		-xelatex \
	  	-auxdir=$(BUILD_DIR) \
		-outdir=$(OUTDIR) \
		-jobname=$(JOBNAME) $(QUIET)

all: $(TAR)

$(TAR_PDF): $(SRC_TEX_A) | $(TAR_DIR)
	$(TEX) -f $(SRC_TEX_X)
	#2> $(LOG)

$(TAR_TEX_BB): $(OUTDIR)/src-bb/%.tex: src/bb/%.tex | $(TAR_DIR)
	rsync -avP --mkpath $< $@

$(TAR_DIR):
	mkdir -p $@

.PHONY: clean
clean-aux:
	# CAUTION USING RM IN SUCH AN ENV
	# USING HARDCODED NAMES AS FAILSAFE
	rm .build/*

clean-pdf:
	# CAUTION USING RM IN SUCH AN ENV
	# USING HARDCODED NAMES AS FAILSAFE
	rm -R .compiled/acorpus.pdf

clean-all:
	# CAUTION USING RM IN SUCH AN ENV
	# USING HARDCODED NAMES AS FAILSAFE
	rm -R .compiled/*

rebuild:
	@$(MAKE) clean-pdf
	@$(MAKE) clean-aux
	@$(MAKE)

test:
	$(info TAR=$(TAR))

open:
	zathura $(TARGETS_PDF) &

log:
	nvim $(LOG)

$(TARBALL): $(TARGETS)
	mkdir -p $(TARBALL_DIR)
	tar -czvf $(TARBALL) --transform 's,^\.compile,doc,' -C . $(OUTDIR)

release-mirror: all
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
		--exclude ".cmp/**" \
		$(CURDIR)/ \
		$(RCLONE_REMOTE):src

release-gh: $(TARBALL)
	gh release create "v$(VERSION)" $(TARBALL) \
        -R $(REPO) \
        --title "$(RELEASE)" \
        --notes "Release notes for $(RELEASE)"

release-local-arc: $(TARBALL)
	cp $(TARBALL) $(ARCHIVE_DIR)/
