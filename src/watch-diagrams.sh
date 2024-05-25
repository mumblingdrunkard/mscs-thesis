#!/bin/sh
i=60000
$(for f in `find . -name "*.d2" -type f`; do \
  d2 \
    --layout=tala \
    --bundle=false \
    --browser=0 \
    --watch \
    --port=$i \
    --font-regular=$TYPST_FONT_PATHS/FiraCode-Regular.ttf \
    --font-bold=$TYPST_FONT_PATHS/FiraCode-Bold.ttf \
    "$f" \
    & \
  i=$((i+1))
done)
wait
