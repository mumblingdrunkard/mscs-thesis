#!/bin/sh
for f in `find . -name "*.d2" -type f`; do \
  d2 --layout tala --theme 301 "$f" \
; done
