#!/usr/bin/make -f

.PHONY: doc test update all tag pypi upload

all:
	@echo "Please use 'python setup.py'."
	@exit 1

install:
	mkdir -p $(PREFIX)/lib/systemd/system
	mkdir -p $(PREFIX)/usr/bin
	mkdir -p $(PREFIX)/usr/lib/distkv
	mkdir -p $(PREFIX)/usr/lib/sysusers.d
	cp systemd/*.service $(PREFIX)/lib/systemd/system/
	cp systemd/*.timer $(PREFIX)/lib/systemd/system/
	cp systemd/sysusers $(PREFIX)/usr/lib/sysusers.d/distkv.conf
	cp scripts/* $(PREFIX)/usr/lib/distkv/
	cp bin/* $(PREFIX)/usr/bin/

# need to use python3 sphinx-build
PATH := /usr/share/sphinx/scripts/python3:${PATH}

PACKAGE = disthass
PYTHON ?= python3
export PYTHONPATH=$(shell pwd)

PYTEST ?= ${PYTHON} $(shell which pytest-3)
TEST_OPTIONS ?= -xvvv --full-trace
PYLINT_RC ?= .pylintrc

BUILD_DIR ?= build
INPUT_DIR ?= docs/source

# Sphinx options (are passed to build_docs, which passes them to sphinx-build)
#   -W       : turn warning into errors
#   -a       : write all files
#   -b html  : use html builder
#   -i [pat] : ignore pattern

SPHINXOPTS ?= -a -W -b html
AUTOSPHINXOPTS := -i *~ -i *.sw* -i Makefile*

SPHINXBUILDDIR ?= $(BUILD_DIR)/sphinx/html
ALLSPHINXOPTS ?= -d $(BUILD_DIR)/sphinx/doctrees $(SPHINXOPTS) docs

doc:
	sphinx-build -a $(INPUT_DIR) $(BUILD_DIR)

livehtml: docs
	sphinx-autobuild $(AUTOSPHINXOPTS) $(ALLSPHINXOPTS) $(SPHINXBUILDDIR)

update:
	pip install -r ci/test-requirements.txt

test:
	$(PYTEST) $(PACKAGE) $(TEST_OPTIONS)

tagged:
	git describe --tags --exact-match
	test $$(git ls-files -m | wc -l) = 0

pypi:	tagged
	python3 setup.py sdist upload
	## version depends on tag, so re-tagging doesn't make sense

upload: pypi
	git push --tags

.PHONY: all tagged pypi upload