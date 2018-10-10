#!/usr/bin/env python

import os, webbrowser, sys

try:
    from urllib import pathname2url
except:
    from urllib.request import pathname2url

DOCKER_HOST = None

if "DOCKER_HOST" in os.environ:
    DOCKER_HOST = os.environ.get("DOCKER_HOST").replace("tcp://", "")
    DOCKER_HOST = "http://{}".format(DOCKER_HOST.replace(":2376", ""))
else:
    print("Sorry.. Env Var DOCKER_HOST is not set, exiting!")

PORT = sys.argv[1]

FINAL_ADDRESS = "{}:{}".format(DOCKER_HOST, PORT)

print("FINAL_ADDRESS: {}".format(FINAL_ADDRESS))

# MacOS
chrome_path = "open -a /Applications/Google\ Chrome.app %s"

webbrowser.get(chrome_path).open(FINAL_ADDRESS)
