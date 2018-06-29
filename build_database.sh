#!/bin/bash
set -e

if [ $# -ne 1 ]
then
    echo "arguments: JSON_SRC" 1>&2
    exit 1
fi

./ck2db.py gamedata
for i in $1/*.json
do
    echo "$i =================================================="
    ./ck2db.py savefile "$i"
done
echo "DONE BUILDING DATABASE"

