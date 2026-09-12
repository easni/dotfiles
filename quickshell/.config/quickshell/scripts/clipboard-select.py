#!/usr/bin/env python3
"""Restore one cliphist entry without exposing its content to QML or a shell."""
import re
import subprocess
import sys


def main():
    if len(sys.argv) != 2 or not re.fullmatch(r"[0-9]+", sys.argv[1]):
        return 2
    try:
        decoded = subprocess.run(
            ["cliphist", "decode"], input=(sys.argv[1] + "\t\n").encode(),
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=False,
        )
        # Never run wl-copy on a failed decode: that could clear the clipboard.
        if decoded.returncode:
            return 1
        copied = subprocess.run(
            ["wl-copy", "--type", "text/plain;charset=utf-8"], input=decoded.stdout,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False,
        )
        return 0 if copied.returncode == 0 else 1
    except OSError:
        return 1


if __name__ == "__main__":
    sys.exit(main())
