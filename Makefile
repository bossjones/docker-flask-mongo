# SOURCE: https://github.com/autopilotpattern/jenkins/blob/master/makefile
MAKEFLAGS += --warn-undefined-variables
# .SHELLFLAGS := -eu -o pipefail

PR_SHA           := $(shell git rev-parse HEAD)
REPO_NAME        := bossjones/docker-flask-mongo
IMAGE_TAG        := $(REPO_NAME):$(PR_SHA)
CONTAINER_NAME   := $(shell echo -n $(IMAGE_TAG) | openssl dgst -sha1 | sed 's/^.* //'  )
MKDIR             = mkdir
define BROWSER_PYSCRIPT
import os, webbrowser, sys
try:
	from urllib import pathname2url
except:
	from urllib.request import pathname2url

webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])))
endef
export BROWSER_PYSCRIPT

BROWSER := python -c "$$BROWSER_PYSCRIPT"

.PHONY: open-coverage-report-html
open-coverage-report-html:
	$(BROWSER) htmlcov/index.html

.PHONY: help
help:
	@echo "make install-dev                 Pip install editable version of this cli tool"

.PHONY: install
install:
	python setup.py install

.PHONY: install-dev
install-dev:
	pip install -e .

.PHONY: force-install-dev
force-install-dev:
	pip install -e . --force-reinstall

.PHONY: install-deps
install-deps:
	pip install -r requirements.txt

.PHONY: install-deps-all
install-deps-all:
	pip install -r requirements.txt; \
	pip install -r requirements-dev.txt; \

.PHONY: install-deps
reinstall-deps-osx:
	env ARCHFLAGS="-arch x86_64" LDFLAGS="-L/usr/local/opt/openssl/lib" CFLAGS="-I/usr/local/opt/openssl/include" pip install --force-reinstall -r requirements.txt

.PHONY: install-deps-all
reinstall-deps-all-osx:
	env ARCHFLAGS="-arch x86_64" LDFLAGS="-L/usr/local/opt/openssl/lib" CFLAGS="-I/usr/local/opt/openssl/include" pip install --force-reinstall -r requirements.txt; \
	env ARCHFLAGS="-arch x86_64" LDFLAGS="-L/usr/local/opt/openssl/lib" CFLAGS="-I/usr/local/opt/openssl/include" pip install --force-reinstall -r requirements-dev.txt; \

.PHONY: install-deps
install-deps-osx:
	env ARCHFLAGS="-arch x86_64" LDFLAGS="-L/usr/local/opt/openssl/lib" CFLAGS="-I/usr/local/opt/openssl/include" pip install -r requirements.txt

.PHONY: install-deps-all
install-deps-all-osx:
	env ARCHFLAGS="-arch x86_64" LDFLAGS="-L/usr/local/opt/openssl/lib" CFLAGS="-I/usr/local/opt/openssl/include" pip install -r requirements.txt; \
	env ARCHFLAGS="-arch x86_64" LDFLAGS="-L/usr/local/opt/openssl/lib" CFLAGS="-I/usr/local/opt/openssl/include" pip install -r requirements-dev.txt; \

.PHONY: install-jupyter-osx
install-jupyter-osx:
	env ARCHFLAGS="-arch x86_64" LDFLAGS="-L/usr/local/opt/openssl/lib" CFLAGS="-I/usr/local/opt/openssl/include" pip install jupyter; \
	env ARCHFLAGS="-arch x86_64" LDFLAGS="-L/usr/local/opt/openssl/lib" CFLAGS="-I/usr/local/opt/openssl/include" python -m ipykernel install --user; \

# sensible pylint ( Lots of press over this during pycon 2018 )
.PHONY: run-black-check
run-black-check:
	black --check --verbose .

.PHONY: run-black
run-black:
	black --verbose .

.PHONY: pip-compile-upgrade-all
pip-compile-upgrade-all:
	pip-compile --output-file requirements.txt requirements.in --upgrade ;\
	pip-compile --output-file requirements-dev.txt requirements-dev.in --upgrade

.PHONY: pip-compile
pip-compile:
	pip-compile --output-file requirements.txt requirements.in ;\
	pip-compile --output-file requirements-dev.txt requirements-dev.in

.PHONY: build
build:
	@echo Building Container

# Build backend container
	docker build \
		--pull --quiet --tag=$(IMAGE_TAG) .
# tag docker hub container with latest
	docker tag $(IMAGE_TAG) $(REPO_NAME):latest

.PHONY: clean-cache
clean-cache:
	find . -name '*.pyc' | xargs rm
	find . -name '__pycache__' | xargs rm -rf

clean-coverge-files:
	rm -rf htmlcov/
	rm -rf cov_annotate/
	rm -rf cov.xml

.PHONY: lint
lint:
	./script/lint

.PHONY: test
test:
	./script/run_pytest

.PHONY: ci
ci:
	.ci/docker-test.sh

.PHONY: run-bash
run-bash:
	./script/docker_run_bash

.PHONY: func-test
func-test:
	.ci/functional-test.sh

.PHONY: mkdir-ptpython
mkdir-ptpython:
	@test -d ~/.ptpython/ || $(MKDIR) -p ~/.ptpython/


.PHONY: cheetsheets
cheetsheets:
	@test -d ~/.cheat/ || git clone https://github.com/bossjones/boss-cheatsheets.git ~/.cheat ; \
	pip install cheat

contrib-tools: mkdir-ptpython cheetsheets
	ln -sfv contrib/.pryrc ~
	ln -sfv contrib/.pdbrc ~
	ln -sfv contrib/.pdbrc.py ~
	ln -sfv contrib/.ptpython_config.py ~/.ptpython/config.py
	ln -sfv contrib/.pythonrc ~
	ln -sfv contrib/.fancycompleterrc.py ~

.PHONY: pip-tools
pip-tools:
	pip install pip-tools pipdeptree


dc-up:
	docker-compose -f docker-compose.yml create && \
	docker-compose -f docker-compose.yml start

dc-down:
	docker-compose -f docker-compose.yml stop && \
	docker-compose -f docker-compose.yml down

dc-restart: dc-down dc-up

dc-build:
	docker-compose build --force-rm --pull

pull:
	docker-compose pull

up: pull
	docker-compose up

dev-up: up

dev-down: down

up-d: pull
	docker-compose up -d

down:
	docker-compose down && \
	docker-compose rm -f

restart: down up

shell:
	docker exec -ti $(IMAGE_TAG):latest /bin/bash
