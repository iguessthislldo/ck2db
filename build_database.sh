#!/bin/bash
set -e

if [ $# -ne 3 ]
then
    echo "arguments: JSON_SRC START_YEAR END_YEAR" 1>&2
    exit 1
fi

start_year=$(printf '%.4d' $(expr "$2" '-' 1))
end_year=$(printf '%.4d' "$3")

#./ck2db.py gamedata
for i in $1/*.json
do
    year=$(basename -s '.json' $i)
    if [ "$year" \> "$start_year~" -a "$year" \< "${end_year}~" ]
    then
        echo "$i =================================================="
        #./ck2db.py savefile "$i"
    fi
done
echo "DONE BUILDING DATABASE"

