
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

TARGETS_DIRS := $(BUILD_DIR)
TARGETS_TEX=$(OUTPUT)/index.pdf

#TARGETS_TEX_X := $(shell find ${SRC_DIRS} -name '*.tex')
#TARGETS_TEX_Y := $(TARGETS_TEX_X:.tex=.pdf)
#TARGETS_TEX := $(TARGETS_TEX_Y:%=${OUTPUT}/%)

TARGETS = $(TARGETS_DIRS) $(TARGETS_A) $(TARGETS_B) $(TARGETS_TEX)

all: $(TARGETS)

#${TARGETS_TEX}: ${OUTPUT}/%.pdf: %.tex | ${OUTPUT}
#	TEXINPUTS=src:src//: pdflatex -output-directory=${BUILD_DIR} $<
#	mv ${BUILD_DIR}/$(basename $(notdir $<)).pdf $@

#temp workaround for build process not recognising when subsidary include based files are updated
build:
	TEXINPUTS=src:src//: pdflatex -output-directory=${BUILD_DIR} index.tex
	mv ${BUILD_DIR}/index.pdf .compiled/index.pdf

${OUTPUT}/README.md: README.md | ${OUTPUT}
	cp "README.md" "${OUTPUT}/README.md"

${TARGETS_DIRS}: %: ${OUTPUT}
	mkdir -p $@

${OUTPUT}:
	mkdir -p $@

.PHONY: clean
clean:
	rm -fR "${OUTPUT}/"

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

