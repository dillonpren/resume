###############################################################################
# Makefile to build resume from private source and generate assets
#
# Targets:
#   make            -> pdf jpg
#   make pdf        -> builds Resume_DillonPrendergast.pdf
#   make jpg        -> builds Resume.jpg (from the PDF)
#   make clean      -> cleans intermediate build artifacts
#
# Requirements:
#   - latexmk (preferred) or pdflatex
#   - ImageMagick (convert or magick)
#
# LaTeX source lives at repo root; public artifacts are written to public/
###############################################################################

.PHONY: all pdf jpg clean template template-pdf template-jpg

TEX_SRC := resume.tex
BUILD_DIR := build
ARCHIVE_DIR := archive
TIMESTAMP := $(shell date +"%Y-%m-%d_%H-%M-%S")

# Template build variables
# Path mode:
# - In private repo, artifacts live in public/
# - In public snapshot repo, artifacts live at repo root
ifneq ("$(wildcard public)","")
ARTIFACT_DIR := public
else
ARTIFACT_DIR := .
endif

PDF_OUT := $(BUILD_DIR)/resume.pdf
PUBLIC_PDF := $(ARTIFACT_DIR)/Resume_DillonPrendergast.pdf
PUBLIC_JPG := $(ARTIFACT_DIR)/Resume.jpg
BUILD_LOG := $(BUILD_DIR)/build.log

TEMPLATE_TEX := $(ARTIFACT_DIR)/template/resume-template.tex
TEMPLATE_PDF_OUT := $(BUILD_DIR)/resume-template.pdf
PUBLIC_TEMPLATE_PDF := $(ARTIFACT_DIR)/template/Resume_Template.pdf
PUBLIC_TEMPLATE_JPG := $(ARTIFACT_DIR)/template/Resume_Template.jpg

# Detect ImageMagick command name (magick on Windows, convert on many Linux distros)
IM_CMD := $(shell command -v magick 2>/dev/null || command -v convert 2>/dev/null)

all: pdf jpg

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(ARCHIVE_DIR):
	mkdir -p $(ARCHIVE_DIR)

# Archive any existing public files before rebuild
archive-existing: | $(ARCHIVE_DIR)
	@if [ -f "$(PUBLIC_PDF)" ]; then \
	  mv "$(PUBLIC_PDF)" "$(ARCHIVE_DIR)/$(basename $(notdir $(PUBLIC_PDF)))_$(TIMESTAMP).pdf"; \
	  echo "Archived old $(PUBLIC_PDF)"; \
	fi
	@if [ -f "$(PUBLIC_JPG)" ]; then \
	  mv "$(PUBLIC_JPG)" "$(ARCHIVE_DIR)/$(basename $(notdir $(PUBLIC_JPG)))_$(TIMESTAMP).jpg"; \
	  echo "Archived old $(PUBLIC_JPG)"; \
	fi

# Build PDF using latexmk if available; fallback to pdflatex (run twice for refs)
pdf: archive-existing $(PUBLIC_PDF)

$(PUBLIC_PDF): $(TEX_SRC) | $(BUILD_DIR)
	@if command -v latexmk >/dev/null 2>&1; then \
	  latexmk -pdf -interaction=nonstopmode -halt-on-error -outdir=$(BUILD_DIR) $(TEX_SRC) > $(BUILD_LOG) 2>&1 || (echo "LaTeX build failed. See $(BUILD_LOG)" && tail -n 50 $(BUILD_LOG) && exit 1); \
	else \
	  (pdflatex -interaction=nonstopmode -halt-on-error -output-directory=$(BUILD_DIR) $(TEX_SRC) && \
	   pdflatex -interaction=nonstopmode -halt-on-error -output-directory=$(BUILD_DIR) $(TEX_SRC)) > $(BUILD_LOG) 2>&1 || (echo "LaTeX build failed. See $(BUILD_LOG)" && tail -n 50 $(BUILD_LOG) && exit 1); \
	fi
	@cp -f $(PDF_OUT) $(PUBLIC_PDF)
	@echo "Built $(PUBLIC_PDF)"

# Generate JPG preview from the public PDF
jpg: $(PUBLIC_JPG)

$(PUBLIC_JPG): $(PUBLIC_PDF)
	@if [ -z "$(IM_CMD)" ]; then \
	  echo "Error: ImageMagick not found (install 'imagemagick')."; \
	  exit 1; \
	fi
	@"$(IM_CMD)" -density 300 "$(PUBLIC_PDF)" -quality 92 -colorspace sRGB -flatten "$(PUBLIC_JPG)"
	@echo "Built $(PUBLIC_JPG)"

clean:
	@if command -v latexmk >/dev/null 2>&1; then \
	  latexmk -C -outdir=$(BUILD_DIR) $(TEX_SRC) || true; \
	fi
	rm -rf $(BUILD_DIR)
	@echo "Cleaned build artifacts"

# ========================= Template targets =========================

template: template-pdf template-jpg

template-pdf: $(PUBLIC_TEMPLATE_PDF)

$(PUBLIC_TEMPLATE_PDF): $(TEMPLATE_TEX) | $(BUILD_DIR)
	@mkdir -p $(dir $(PUBLIC_TEMPLATE_PDF))
	@if command -v latexmk >/dev/null 2>&1; then \
	  latexmk -pdf -interaction=nonstopmode -halt-on-error -outdir=$(BUILD_DIR) $(TEMPLATE_TEX) > $(BUILD_LOG) 2>&1 || (echo "LaTeX build failed. See $(BUILD_LOG)" && tail -n 50 $(BUILD_LOG) && exit 1); \
	else \
	  (pdflatex -interaction=nonstopmode -halt-on-error -output-directory=$(BUILD_DIR) $(TEMPLATE_TEX) && \
	   pdflatex -interaction=nonstopmode -halt-on-error -output-directory=$(BUILD_DIR) $(TEMPLATE_TEX)) > $(BUILD_LOG) 2>&1 || (echo "LaTeX build failed. See $(BUILD_LOG)" && tail -n 50 $(BUILD_LOG) && exit 1); \
	fi
	@cp -f $(TEMPLATE_PDF_OUT) $(PUBLIC_TEMPLATE_PDF)
	@echo "Built $(PUBLIC_TEMPLATE_PDF)"

template-jpg: $(PUBLIC_TEMPLATE_JPG)

$(PUBLIC_TEMPLATE_JPG): $(PUBLIC_TEMPLATE_PDF)
	@if [ -z "$(IM_CMD)" ]; then \
	  echo "Error: ImageMagick not found (install 'imagemagick')."; \
	  exit 1; \
	fi
	@"$(IM_CMD)" -density 300 "$(PUBLIC_TEMPLATE_PDF)" -quality 92 -colorspace sRGB -flatten "$(PUBLIC_TEMPLATE_JPG)"
	@echo "Built $(PUBLIC_TEMPLATE_JPG)"
