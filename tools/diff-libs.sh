#!/bin/sh

nm -m $1 | sed -Ee 's,[0-9a-f]{16} ,,g' -e '/undefined/d' > ours
nm -m /usr/lib/system/libcompiler_rt.dylib | sed -Ee 's,[0-9a-f]{16} ,,g' -e '/undefined/d' > apples
sort ours > ours.sorted
sort apples > apples.sorted
diff -u ours.sorted apples.sorted > apis.diff

rm ours ours.sorted apples apples.sorted
