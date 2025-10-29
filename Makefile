VERSION 			:= 0.1.3
RCLONE_REMOTE		:= g1-bigb
REPO				:= aorao/bigbook

RELEASE 			:= Document Release v$(VERSION)
TARBALL_DIR 		:= .release
TARBALL 			:= $(TARBALL_DIR)/compiled_v$(VERSION).tar.gz

BUILD_DIR			:= .build
OUTDIR              := .compiled
OUTDIR_TXT			:= $(OUTDIR)/src-txt
OUTDIR_PDF			:= $(OUTDIR)/basictext
LOG					:= /tmp/bbx-make.log

#QUIET				:= -quiet
JOBNAME				:= basictext

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
	$(OUTDIR_TXT)/$(shell basename $(shell dirname $(src)))/$(shell basename $(src)))

TAR_DIR 	:= $(BUILD_DIR) $(OUTDIR_PDF) $(OUTDIR_TXT) $(TARBALL_DIR)

TAR_PDF		:= $(OUTDIR_PDF)/$(JOBNAME).pdf

TAR_READ    := $(OUTDIR)/README

TAR 		:= $(TAR_DIR) $(TAR_PDF) $(TAR_TEX_BB)

TEX = latexmk \
		-xelatex \
	  	-auxdir=$(BUILD_DIR) \
		-outdir=$(OUTDIR_PDF) \
		-jobname=$(JOBNAME) $(QUIET)

all: $(TAR)

$(TAR_PDF): $(SRC_TEX_A) | $(TAR_DIR)
	$(TEX) -f $(SRC_TEX_X)
	#2> $(LOG)

$(TAR_TEX_BB): $(OUTDIR_TXT)/%.tex: src/bb/%.tex | $(TAR_DIR)
	rsync -avP \
		--mkpath \
		--delete \
		$< $@

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
	rm -R .compiled/basictext/basictext.pdf

clean-all: clean-aux
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
	zathura $(TAR_PDF) &

log:
	nvim $(LOG)

$(TARBALL): all
	tar \
		-czvf $(TARBALL) \
		--transform 's,^\.compile,doc,' \
		-C . $(OUTDIR)

release-mirror: all
	rclone sync \
		-P \
		--track-renames \
		$(CURDIR)/$(OUTDIR) \
		$(RCLONE_REMOTE):doc
	
	rclone sync \
		-P \
		--track-renames \
		--exclude ".git/**" \
		--exclude "$(OUTDIR)/**" \
		--exclude "$(BUILD_DIR)/**" \
		--exclude "$(TARBALL_DIR)/**" \
		--exclude ".cmp/**" \
		$(CURDIR)/ \
		$(RCLONE_REMOTE):src

release-gh: $(TARBALL)
	gh release create \
		"v$(VERSION)" \
		$(TARBALL) \
        -R $(REPO) \
        --title "$(RELEASE)" \
        --notes "Release notes for $(RELEASE)"

release-local-arc: $(TARBALL)
	cp $(TARBALL) $(ARCHIVE_DIR)/
