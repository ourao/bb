# compilation

VERSION = 0.0.1
RCLONE_REMOTE=bigbook
REPO=aorao/bundoran-aa-group

RELEASE = Document Release v${VERSION}
TARBALL_DIR = .release
TARBALL = ${TARBALL_DIR}/compiled_v${VERSION}.tar.gz

BUILD_DIR=.build
LOG=${BUILD_DIR}/make.log
OUTPUT=.compiled

TARGETS_DIRS := $(BUILD_DIR) ${OUTPUT}
TARGETS_TEX=$(OUTPUT)/index.pdf

SRC_DIRS := src

SRC_TEX_X := $(shell find ${SRC_DIRS} -name '*.tex')
#TARGETS_TEX_Y := $(SRC_TEX_X:.tex=.pdf)
#TARGETS_TEX_A := $(TARGETS_TEX_Y:%=${OUTPUT}/%)

SRC_TEX_B := index.tex
SRC_TEX_A := $(SRC_TEX_X) index.tex

TARGETS = $(TARGETS_DIRS) $(TARGETS_A) $(TARGETS_B) $(TARGETS_TEX_A) $(TARGETS_TEX)

all: $(TARGETS)

${TARGETS_TEX}: ${OUTPUT}/%.pdf: $(SRC_TEX_A) | ${TARGET_DIRS}
	TEXINPUTS=src:src//: pdflatex -output-directory=${BUILD_DIR} $(SRC_TEX_B)
	TEXINPUTS=src:src//: pdflatex -output-directory=${BUILD_DIR} $(SRC_TEX_B)
	cp ${BUILD_DIR}/index.pdf $@

${OUTPUT}/README.md: README.md | ${TARGET_DIRS}

	cp "README.md" "${OUTPUT}/README.md"

${TARGETS_DIRS}:
	mkdir -p $@

.PHONY: clean
clean:
	rm -R ".compiled/"
	rm -R ".build/"

rebuild:
	@$(MAKE) clean
	@$(MAKE) all

open:
	zathura .compiled/index.pdf &

$(TARBALL): ${TARGETS}
	mkdir -p ${TARBALL_DIR}
	tar -czvf $(TARBALL) --transform 's,^\.compile,doc,' -C . $(OUTPUT)

mirror: all
	# release compiled and src into separate hierarchies on the remote
	rclone sync \
		-P --track-renames \
		${CURDIR}/${OUTPUT} \
		${REMOTE}:doc
	
	rclone sync \
		-P --track-renames \
		--exclude ".compiled/**" \
		--exclude ".build/**" \
		--exclude ".git/**" \
		--exclude ".release/**" \
		${CURDIR}/ \
		${REMOTE}:src

release-gh: $(TARBALL)
	gh release create "v$(VERSION)" $(TARBALL) \
        -R $(REPO) \
        --title "$(RELEASE)" \
        --notes "Release notes for $(RELEASE)"

release-archive: $(TARBALL)
	cp $(TARBALL) $(ARCHIVE_DIR)/

