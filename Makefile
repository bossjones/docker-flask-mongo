# SOURCE: https://github.com/autopilotpattern/jenkins/blob/master/makefile
MAKEFLAGS += --warn-undefined-variables
# .SHELLFLAGS := -eu -o pipefail

URL_PATH_MONGO_EXPRESS := 8081
URL_PATH_FLASK_APP     := 8888
URL_PATH_UWSGI_STATS   := 9191
URL_PATH_LOCUST_MASTER := 8089
URL_PATH_CONSUL        := 8500
URL_PATH_TRAEFIK       := 80
URL_PATH_TRAEFIK_API   := 8080
URL_PATH_WHOAMI        := 4110


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

default: help

help: ## Help dialog
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-40s\033[0m %s\n", $$1, $$2}'

.PHONY: install
install: ## installs app using python setup.py install
	python setup.py install

.PHONY: install-dev
install-dev: ## installs app w/ dev packages using python setup.py install
	pip install -e .

.PHONY: force-install-dev
force-install-dev: ## FORCE installs app w/ dev packages using python setup.py install
	pip install -e . --force-reinstall

.PHONY: install-deps
install-deps: ## Installs requirements.txt
	pip install -r requirements.txt

.PHONY: install-deps-all
install-deps-all: ## Installs requirements.txt and requirements-dev.txt
	pip install -r requirements.txt; \
	pip install -r requirements-dev.txt; \

.PHONY: install-deps
reinstall-deps-osx: ## Re-Install requirements.txt w/ homebrew environment variables defined
	env ARCHFLAGS="-arch x86_64" LDFLAGS="-L/usr/local/opt/openssl/lib" CFLAGS="-I/usr/local/opt/openssl/include" pip install --force-reinstall -r requirements.txt

.PHONY: install-deps-all
reinstall-deps-all-osx: ## Re-Install requirements.txt and requirements-dev.txt w/ homebrew environment variables defined
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


# dc-up:
# 	docker-compose -f docker-compose.yml create && \
# 	docker-compose -f docker-compose.yml start

dc-up:
	docker-compose -f docker-compose.yml up -d

dc-down:
	docker-compose -f docker-compose.yml stop && \
	docker-compose -f docker-compose.yml down

dc-restart: dc-down dc-up

dc-build-force:
	docker-compose build --force-rm --pull

dc-build:
	docker-compose build

pull:
	docker-compose pull

up: pull
	docker-compose up -d

dev-up: up

dev-down: down

# up-d: pull
# 	docker-compose up -d

down:
	docker-compose down && \
	docker-compose rm -f

restart: down up

shell:
	docker exec -ti $(IMAGE_TAG):latest /bin/bash

tail:
	./scripts/logs-ccze

logs: tail

rebuild: dc-build dc-up

open-mongo-express:
	./scripts/open-browser.py $(URL_PATH_MONGO_EXPRESS)

open-flask-app:
	./scripts/open-browser.py $(URL_PATH_FLASK_APP)

open-uwsgi-stats:
	./scripts/open-browser.py $(URL_PATH_UWSGI_STATS)

open-locust-master:
	./scripts/open-browser.py $(URL_PATH_LOCUST_MASTER)

open-consul:
	./scripts/open-browser.py $(URL_PATH_CONSUL)

open-traefik:
	./scripts/open-browser.py $(URL_PATH_TRAEFIK)

open-traefik-api:
	./scripts/open-browser.py $(URL_PATH_TRAEFIK_API)

open-whoami:
	./scripts/open-browser.py $(URL_PATH_WHOAMI)

open: open-mongo-express open-flask-app open-uwsgi-stats open-locust-master open-consul open-traefik open-traefik-api open-whoami
