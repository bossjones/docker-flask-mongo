#!/usr/bin/env python

# SOURCE: https://github.com/lmm-git/docker-flask-webserver/blob/4bd2105ab41767f85096d9d0c49dc41a48559ae6/docker-config/supervisord-kill.py

import sys
import os
import signal


def write_stdout(s):
    sys.stdout.write(s)
    sys.stdout.flush()


def write_stderr(s):
    sys.stderr.write(s)
    sys.stderr.flush()


def main():
    while 1:
        write_stdout("READY\n")
        line = sys.stdin.readline()
        write_stdout("This line kills supervisor: " + line)
        try:
            pidfile = open("/var/run/supervisord.pid", "r")
            pid = int(pidfile.readline())
            os.kill(pid, signal.SIGQUIT)
        except Exception as e:
            write_stdout("Could not kill supervisor: " + e.strerror + "\n")
            write_stdout("RESULT 2\nOK")


if __name__ == "__main__":
    main()
