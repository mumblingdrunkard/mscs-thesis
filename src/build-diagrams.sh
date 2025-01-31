#!/bin/sh
for f in `find . -name "*.d2" -type f`; do \
  d2 --layout=tala --theme=301 \
    --bundle=false \
    --font-regular=$TYPST_FONT_PATHS/FiraCode-Regular.ttf \
    --font-bold=$TYPST_FONT_PATHS/FiraCode-Bold.ttf \
    "$f" \
    & \
done
wait
