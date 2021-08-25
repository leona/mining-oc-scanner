#!/bin/bash

# Require root
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

python3 src/app.py "$@"