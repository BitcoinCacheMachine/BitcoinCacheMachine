#!/bin/bash
set -e

# TODO implement stragetgy here: https://en.bitcoin.it/wiki/Splitting_the_data_directory

BLK_TARGET=/bitcoin/old_blocks

find . -name '*.dat' -type f -printf '%f\n' > tomove
while read line; do
    echo $line
    mv "$line" "$BLK_TARGET/$line"
    ln -s "$BLK_TARGET/$line" "$line"
done <tomove
rm tomove
echo Done