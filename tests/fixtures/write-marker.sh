#!/bin/sh
# Writes its arguments to /tmp/marker so the next run can check them.
set -eu
printf "%s\n" "$*" > /tmp/marker
echo "marker written by $(id -un)"
