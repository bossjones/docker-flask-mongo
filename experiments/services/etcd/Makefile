define BROWSER_PYSCRIPT
import os, webbrowser, sys
try:
	from urllib import pathname2url
except:
	from urllib.request import pathname2url

webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])))
endef
export BROWSER_PYSCRIPT

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT
BROWSER := python -c "$$BROWSER_PYSCRIPT"


etcd-browser:
	@test -d etcd-browser || git clone git@github.com:henszey/etcd-browser.git

dc-up:
	docker-compose up -d

verify:
	./validate.sh

validate: verify

ETCD_BROWSER_ADDRESS := $(shell ./bin/service_address.sh etcd-browser 8000)

.PHONY: open-etcd-browser
open-etcd-browser:
	$(BROWSER) $(ETCD_BROWSER_ADDRESS)
