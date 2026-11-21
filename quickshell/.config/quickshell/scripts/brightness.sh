#!/bin/bash
case "$1" in
    +[0-9]*%) exec qs ipc call luci brightnessStep "${1:1:-1}" ;;
    [0-9]*%-) exec qs ipc call luci brightnessStep "-${1%\%-}" ;;
    [0-9]*%) exec qs ipc call luci brightnessSet "${1%\%}" ;;
esac
exit 1
